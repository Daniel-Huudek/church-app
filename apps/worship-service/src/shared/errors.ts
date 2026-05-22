export class AppError extends Error {
  statusCode: number;
  code?: string;
  constructor(message: string, statusCode: number = 400, code?: string) {
    super(message);
    this.statusCode = statusCode;
    this.code = code;
    this.name = 'AppError';
  }
}
export class NotFoundError extends AppError {
  constructor(message: string = 'Resource not found') { super(message, 404, 'NOT_FOUND'); }
}
export class UnauthorizedError extends AppError {
  constructor(message: string = 'Unauthorized') { super(message, 401, 'UNAUTHORIZED'); }
}
export class ConflictError extends AppError {
  constructor(message: string = 'Conflict') { super(message, 409, 'CONFLICT'); }
}
