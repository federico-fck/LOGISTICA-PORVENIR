import { Usuario } from './usuario.model';

export interface LoginRequest {
  usuario: string;
  password: string;
}

export interface LoginResponse {
  access_token: string;
  usuario: Usuario;
}
