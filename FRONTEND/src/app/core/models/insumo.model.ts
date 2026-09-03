export interface CategoriaInsumo {
  idCategoria: number;
  nombreCategoria: string;
  descripcion?: string;
  estado?: string;
}

export interface TipoInsumo {
  idTipoInsumo: number;
  nombreTipo: string;
  descripcion?: string;
  estado?: string;
}

export interface UnidadMedida {
  idUnidadMedida: number;
  nombreUnidad: string;
  abreviatura?: string;
  estado?: string;
}

export interface Insumo {
  idInsumo: number;
  codigoInterno: string;
  nombreInsumo: string;
  descripcion?: string;
  stockMinimo?: number;
  stock_minimo?: number;
  precioReferencial?: number;
  precio_referencial?: number;
  estado: string;

  idCategoria?: number;
  idTipoInsumo?: number;
  idUnidadMedida?: number;

  categoria?: CategoriaInsumo | null;
  categoriaInsumo?: CategoriaInsumo | null;

  tipo?: TipoInsumo | null;
  tipoInsumo?: TipoInsumo | null;

  unidad?: UnidadMedida | null;
  unidadMedida?: UnidadMedida | null;
}

export interface CatalogosInsumos {
  categorias: CategoriaInsumo[];
  tipos?: TipoInsumo[];
  tiposInsumo?: TipoInsumo[];
  unidadesMedida: UnidadMedida[];
}
