export interface User {
  id?: number;
  fullName: string;
  email: string;
  role: string;
  biography?: string;
  level?: string;
  goals?: string;
}

export interface AuthResponse {
  token: string;
  user: User;
}








