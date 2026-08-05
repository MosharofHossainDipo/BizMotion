export interface LoginRequest  { username: string; password: string; }
export interface RegisterRequest { username: string; email: string; password: string; confirmPassword: string; }
export interface AuthResponse  { accessToken: string; refreshToken: string; role: string; scopes: string[]; username: string; userId: number; }