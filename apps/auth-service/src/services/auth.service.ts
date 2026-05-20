import { PrismaClient, User, Role, Permission as PrismaPermission } from '@prisma/client';
import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { AppError, UnauthorizedError, ConflictError } from '../shared';
import { logger } from '../logger';

interface TokenPayload {
  userId: string;
  email: string;
  role: Role;
  permissions: Permission[];
}

export class AuthService {
  private jwtSecret: string;
  private jwtExpiresIn: string;
  private refreshExpiresIn: string;

  constructor(private prisma: PrismaClient) {
    this.jwtSecret = process.env.JWT_SECRET || 'default-secret';
    this.jwtExpiresIn = process.env.JWT_EXPIRES_IN || '15m';
    this.refreshExpiresIn = process.env.JWT_REFRESH_EXPIRES_IN || '7d';
  }

  async register(name: string, email: string, password: string) {
    const existing = await this.prisma.user.findUnique({ where: { email } });
    if (existing) throw new ConflictError('Email already registered');

    const hashedPassword = await bcrypt.hash(password, 10);
    const user = await this.prisma.user.create({
      data: { name, email, password: hashedPassword, role: 'MEMBRO', permissions: [] },
    });

    return this.generateTokens(user);
  }

  async login(email: string, password: string) {
    const user = await this.prisma.user.findUnique({ where: { email } });
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

  async handleGoogleIdToken(idToken: string) {
    const { OAuth2Client } = await import('google-auth-library');
    const client = new OAuth2Client(process.env.GOOGLE_CLIENT_ID);

    const ticket = await client.verifyIdToken({ idToken, audience: process.env.GOOGLE_CLIENT_ID });
    const payload = ticket.getPayload();

    if (!payload) throw new AppError('Invalid Google token', 400);

    return this.findOrCreateGoogleUser(payload);
  }

  private async findOrCreateGoogleUser(payload: { sub: string; email?: string; name?: string; picture?: string }) {
    let user = await this.prisma.user.findUnique({ where: { googleId: payload.sub } });

    if (!user) {
      user = await this.prisma.user.findUnique({ where: { email: payload.email! } });
      if (user) {
        user = await this.prisma.user.update({ where: { id: user.id }, data: { googleId: payload.sub, avatar: payload.picture } });
      } else {
        user = await this.prisma.user.create({
          data: { email: payload.email!, name: payload.name!, googleId: payload.sub, avatar: payload.picture, role: 'MEMBRO', permissions: [] },
        });
      }
    }

    return this.generateTokens(user);
  }

  async refreshToken(refreshToken: string) {
    const token = await this.prisma.refreshToken.findUnique({ where: { token: refreshToken } });
    if (!token || token.expiresAt < new Date()) throw new UnauthorizedError('Invalid refresh token');

    const user = await this.prisma.user.findUnique({ where: { id: token.userId } });
    if (!user) throw new UnauthorizedError('User not found');

    await this.prisma.refreshToken.delete({ where: { id: token.id } });
    return this.generateTokens(user);
  }

  async logout(token: string) {
    await this.prisma.session.deleteMany({ where: { token } });
    await this.prisma.refreshToken.deleteMany({ where: { token } });
  }

  private async generateTokens(user: User) {
    const payload: TokenPayload = { userId: user.id, email: user.email, role: user.role, permissions: user.permissions as Permission[] };

    const accessToken = jwt.sign(payload, this.jwtSecret, { expiresIn: this.jwtExpiresIn });
    const refreshTokenValue = crypto.randomUUID();
    const expiresAt = new Date(Date.now() + 7 * 24 * 60 * 60 * 1000);

    await this.prisma.refreshToken.create({ data: { userId: user.id, token: refreshTokenValue, expiresAt } });

    return { success: true, data: { accessToken, refreshToken: refreshTokenValue, user: { id: user.id, email: user.email, name: user.name, role: user.role, avatar: user.avatar } } };
  }

  async setUserPermissions(userId: string, permissions: string[]) {
    const validPermissions = permissions.filter(p => 
      ['users_read', 'users_write', 'users_delete', 'members_read', 'members_write', 'members_delete', 
       'events_read', 'events_write', 'events_delete', 'prayers_read', 'prayers_write', 'prayers_delete',
       'finance_read', 'finance_write', 'finance_delete'].includes(p)
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
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
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

  async updateUserRole(userId: string, role: string) {
    const validRoles = ['ADMINISTRADOR', 'PASTOR', 'FINANCEIRO', 'LIDER', 'MEMBRO', 'VISITANTE'];
    if (!validRoles.includes(role)) {
      throw new AppError('Invalid role', 400);
    }
    const user = await this.prisma.user.update({
      where: { id: userId },
      data: { role: role as any },
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
}