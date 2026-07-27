import { PrismaClient, User, Role, Permission as PrismaPermission } from '@prisma/client';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { AppError, UnauthorizedError, ConflictError } from '@church-app/shared';

interface TokenPayload {
  userId: string;
  email: string;
  role: Role;
  permissions: PrismaPermission[];
}

export class AuthService {
  private jwtSecret: string;
  private jwtExpiresIn: string;
  private refreshExpiresIn: string;

  constructor(private prisma: PrismaClient) {
    if (!process.env.JWT_SECRET) {
      throw new Error('JWT_SECRET environment variable is required');
    }
    this.jwtSecret = process.env.JWT_SECRET;
    this.jwtExpiresIn = process.env.JWT_EXPIRES_IN || '15m';
    this.refreshExpiresIn = process.env.JWT_REFRESH_EXPIRES_IN || '7d';
  }

  async register(name: string, email: string, password: string) {
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictError('Email already registered');

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await this.prisma.user.create({
      data: { name, email, password: hashedPassword, role: 'VISITANTE', permissions: [] },
    });

    return this.generateTokens(user);
  }

  async login(email: string, password: string) {
    const user = await this.prisma.user.findFirst({ where: { email, deletedAt: null } });
    if (!user || !user.password) throw new UnauthorizedError('Invalid credentials');

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) throw new UnauthorizedError('Invalid credentials');

    return this.generateTokens(user);
  }

  async handleGoogleCallback(code: string) {
    const { OAuth2Client } = await import('google-auth-library');
    const client = new OAuth2Client(
      process.env.GOOGLE_CLIENT_ID,
      process.env.GOOGLE_CLIENT_SECRET,
      process.env.GOOGLE_REDIRECT_URI
    );

    const { tokens } = await client.getToken(code);
    const ticket = await client.verifyIdToken({ idToken: tokens.id_token! });
    const payload = ticket.getPayload();

    if (!payload) throw new AppError('Invalid Google token', 400);

    return this.findOrCreateGoogleUser(payload);
  }

  async handleGoogleToken(token: string) {
    try {
      const { OAuth2Client } = await import('google-auth-library');
      const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);
      const ticket = await client.verifyIdToken({ idToken: token, audience: process.env.GOOGLE_CLIENT_ID });
      const payload = ticket.getPayload();
      if (!payload) throw new Error();
      return this.findOrCreateGoogleUser(payload);
    } catch {
      const response = await fetch(`https://www.googleapis.com/oauth2/v3/userinfo?access_token=${token}`);
      if (!response.ok) throw new AppError('Invalid Google token', 400);
      const userInfo = await response.json() as { sub: string; email: string; name: string; picture?: string };
      return this.findOrCreateGoogleUser({ sub: userInfo.sub, email: userInfo.email, name: userInfo.name, picture: userInfo.picture });
    }
  }

  private async findOrCreateGoogleUser(payload: { sub: string; email?: string; name?: string; picture?: string }) {
    let user = await this.prisma.user.findFirst({ where: { googleId: payload.sub, deletedAt: null } });

    if (!user) {
      user = await this.prisma.user.findFirst({ where: { email: payload.email!, deletedAt: null } });
      if (user) {
        user = await this.prisma.user.update({ where: { id: user.id }, data: { googleId: payload.sub, avatar: payload.picture } });
      } else {
        user = await this.prisma.user.create({
          data: { email: payload.email!, name: payload.name!, googleId: payload.sub, avatar: payload.picture, role: 'VISITANTE', permissions: [] },
        });
      }
    } else if (payload.picture) {
      user = await this.prisma.user.update({ where: { id: user.id }, data: { avatar: payload.picture } });
    }

    return this.generateTokens(user);
  }

  async refreshToken(refreshToken: string) {
    const token = await this.prisma.refreshToken.findUnique({ where: { token: refreshToken } });
    if (!token || token.expiresAt < new Date()) throw new UnauthorizedError('Invalid refresh token');

    const user = await this.prisma.user.findFirst({ where: { id: token.userId, deletedAt: null } });
    if (!user) throw new UnauthorizedError('User not found');

    await this.prisma.refreshToken.delete({ where: { id: token.id } });
    return this.generateTokens(user);
  }

  async logout(token: string) {
    await this.prisma.session.deleteMany({ where: { token } });
    await this.prisma.refreshToken.deleteMany({ where: { token } });
  }

  private async generateTokens(user: User) {
    const payload: TokenPayload = { userId: user.id, email: user.email, role: user.role, permissions: user.permissions as PrismaPermission[] };

    const accessToken = jwt.sign(payload, this.jwtSecret, { expiresIn: this.jwtExpiresIn });
    const refreshTokenValue = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await this.prisma.refreshToken.create({ data: { userId: user.id, token: refreshTokenValue, expiresAt } });

    return { success: true, data: { accessToken, refreshToken: refreshTokenValue, user: { id: user.id, email: user.email, name: user.name, role: user.role, avatar: user.avatar, permissions: user.permissions, createdAt: user.createdAt, updatedAt: user.updatedAt } } };
  }

  async setUserPermissions(userId: string, permissions: string[]) {
    const validPermissions = permissions.filter(p => 
      ['users_read','users_write','users_delete','members_read','members_write','members_delete',
       'members_export','members_import','ministries_read','ministries_write','ministries_delete',
       'schedules_read','schedules_write','schedules_delete','events_read','events_write','events_delete',
       'prayers_read','prayers_write','prayers_delete','prayers_comment','prayers_react',
       'finance_read','finance_write','finance_delete','finance_export','finance_audit','finance_close',
       'finance_reports','notifications_send'].includes(p)
    ) as PrismaPermission[];
    
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { permissions: validPermissions },
    });
    return user;
  }

  async getUserPermissions(userId: string) {
    const user = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!user) throw new AppError('User not found', 404);
    return user.permissions;
  }

  async getAllUsers() {
    const users = await this.prisma.user.findMany({
      where: { deletedAt: null },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        permissions: true,
        avatar: true,
        createdAt: true,
      },
    });
    return users;
  }

  async getUserById(userId: string) {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, deletedAt: null },
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        permissions: true,
        avatar: true,
        createdAt: true,
      },
    });
    if (!user) throw new AppError('User not found', 404);
    return user;
  }

  async updateUser(userId: string, data: { role?: string; name?: string; email?: string; avatar?: string }) {
    const updateData: any = {};
    if (data.role) {
      const validRoles = ['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO', 'LIDER', 'LIDER_LOUVOR', 'LOUVOR', 'LIDER_DIACONOS', 'DIACONO', 'MEMBRO', 'VISITANTE'];
      if (!validRoles.includes(data.role)) throw new AppError('Invalid role', 400);
      updateData.role = data.role;
    }
    if (data.name) updateData.name = data.name;
    if (data.email) {
      const existing = await this.prisma.user.findFirst({ where: { email: data.email, deletedAt: null } });
      if (existing && existing.id !== userId) throw new ConflictError('Email already in use');
      updateData.email = data.email;
    }
    if (data.avatar !== undefined) updateData.avatar = data.avatar;
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: updateData,
      select: {
        id: true,
        email: true,
        name: true,
        role: true,
        permissions: true,
        avatar: true,
        createdAt: true,
      },
    });
    return user;
  }

  async getAllRoles() {
    const roles = await this.prisma.roleConfig.findMany({ orderBy: { name: 'asc' } });
    if (roles.length === 0) {
      return this._seedDefaultRoles();
    }
    return roles;
  }

  async updateRole(name: string, permissions: string[]) {
    return this.prisma.roleConfig.upsert({
      where: { name },
      update: { permissions: permissions as any },
      create: { name, permissions: permissions as any },
    });
  }

  async resetRoles() {
    await this.prisma.roleConfig.deleteMany();
    return this._seedDefaultRoles();
  }

  private async _seedDefaultRoles() {
    const defaults: { name: string; perms: string[] }[] = [
      { name: 'ADMINISTRADOR', perms: ['users_write','users_delete','members_write','members_delete','events_write','events_delete','prayers_write','prayers_delete','finance_write','finance_delete'] },
      { name: 'PASTOR', perms: ['users_write','users_delete','members_write','members_delete','events_write','events_delete','prayers_write','prayers_delete','finance_write','finance_delete'] },
      { name: 'FINANCEIRO', perms: ['finance_write','finance_delete'] },
      { name: 'LIDER', perms: ['members_write','members_delete','events_write','events_delete','prayers_write','prayers_delete'] },
      { name: 'LIDER_LOUVOR', perms: ['events_write','events_delete'] },
      { name: 'LOUVOR', perms: [] },
      { name: 'LIDER_DIACONOS', perms: ['events_write','schedules_write'] },
      { name: 'DIACONO', perms: ['schedules_read'] },
      { name: 'MEMBRO', perms: ['prayers_write','prayers_delete'] },
      { name: 'VISITANTE', perms: [] },
    ];
    for (const r of defaults) {
      await this.prisma.roleConfig.create({ data: { name: r.name, permissions: r.perms as any } });
    }
    return this.prisma.roleConfig.findMany({ orderBy: { name: 'asc' } });
  }
}