export interface MenuItem {
  titulo: string;
  ruta: string;
  icono: string;
  roles?: string[];
  permiso?: string;
  permisos?: string[];
}

export interface MenuGroup {
  grupo: string;
  items: MenuItem[];
}
