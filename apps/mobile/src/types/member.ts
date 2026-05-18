export interface Member {
  id: string;
  name: string;
  email: string;
  phone: string;
  birthDate: string;
  cpf?: string;
  rg?: string;
  gender?: 'MASCULINO' | 'FEMININO' | 'OUTRO';
  maritalStatus?: 'SOLTEIRO' | 'CASADO' | 'DIVORCIADO' | 'VIUVO' | 'SEPARADO';
  profession?: string;
  address?: Address;
  avatar?: string;
  status: 'ATIVO' | 'INATIVO' | 'TRANSFERIDO' | 'FALECIDO';
  baptismDate?: string;
  conversionDate?: string;
  membershipDate?: string;
  role: 'ADMINISTRADOR' | 'PASTOR' | 'FINANCEIRO' | 'MEMBRO' | 'VISITANTE';
  ministries: string[];
  notes?: string;
  createdAt: string;
  updatedAt: string;
}

export interface Address {
  street: string;
  number: string;
  complement?: string;
  neighborhood: string;
  city: string;
  state: string;
  zipCode: string;
  country: string;
}

export interface MemberHistory {
  id: string;
  memberId: string;
  action: string;
  description: string;
  changes?: Record<string, { old: unknown; new: unknown }>;
  authorId: string;
  authorName: string;
  createdAt: string;
}

export interface MemberDocument {
  id: string;
  memberId: string;
  type: string;
  name: string;
  fileUrl: string;
  fileSize?: number;
  mimeType?: string;
  notes?: string;
  uploadedById: string;
  uploadedByName: string;
  createdAt: string;
  updatedAt: string;
}

export interface MemberFamily {
  id: string;
  memberId: string;
  relatedMemberId: string;
  relatedMemberName: string;
  relationship:
    | 'CONJUGE'
    | 'FILHO'
    | 'FILHA'
    | 'PAI'
    | 'MAE'
    | 'IRMAO'
    | 'IRMA'
    | 'AVO'
    | 'NETO'
    | 'TIO'
    | 'TIA'
    | 'PRIMO'
    | 'PRIMA'
    | 'OUTRO';
  isDependent: boolean;
  createdAt: string;
}

export interface MemberFilter {
  page?: number;
  limit?: number;
  name?: string;
  email?: string;
  status?: string;
  role?: string;
  gender?: string;
  maritalStatus?: string;
  ministryId?: string;
  city?: string;
  state?: string;
  birthDateFrom?: string;
  birthDateTo?: string;
  membershipDateFrom?: string;
  membershipDateTo?: string;
  search?: string;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export interface PaginatedResponse<T> {
  success: boolean;
  data: {
    data: T[];
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}
