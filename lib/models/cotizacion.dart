/// lib/models/cotizacion.dart
///
/// Modelos que reflejan exactamente el JSON que devuelve
/// cotizador_service.py -> cotizar_receta() en el backend, expuesto via
/// POST /api/cotizador/cotizar (cotizador_router.py).
///
/// v3 (04-08-2026): se elimino el sistema de 3 niveles
/// (economico/intermedio/premium, antes en NivelPaquete). El backend
/// ahora devuelve un solo total + items por farmacia (el mas barato
/// disponible por item, sin distincion de nivel de confianza de
/// laboratorio) -- ver docstring de cotizador_service.py para el
/// motivo del cambio. NivelPaquete y el campo "niveles" ya no existen.
library;

/// Un item de la receta que se envia a cotizar (request).
class ItemReceta {
  final String principioActivo;
  final String? presentacion;

  ItemReceta({required this.principioActivo, this.presentacion});

  Map<String, dynamic> toJson() => {
        'principio_activo': principioActivo,
        if (presentacion != null) 'presentacion': presentacion,
      };
}

/// Un producto especifico encontrado en una farmacia.
class ProductoCotizado {
  final String? sku;
  final String nombreComercial;
  final String? laboratorio;
  final int? precioNormal;
  final int? precioOferta;
  final int precioFinal;
  final bool disponible;
  final bool? requiereReceta;
  final bool? despachoDomicilio;
  final bool? retiroTienda;
  final bool? esBioequivalente;
  final String? imagenUrl;
  final String? urlProducto;

  ProductoCotizado({
    this.sku,
    required this.nombreComercial,
    this.laboratorio,
    this.precioNormal,
    this.precioOferta,
    required this.precioFinal,
    required this.disponible,
    this.requiereReceta,
    this.despachoDomicilio,
    this.retiroTienda,
    this.esBioequivalente,
    this.imagenUrl,
    this.urlProducto,
  });

  factory ProductoCotizado.fromJson(Map<String, dynamic> json) {
    return ProductoCotizado(
      sku: json['sku']?.toString(),
      nombreComercial: json['nombre_comercial'] ?? '',
      laboratorio: json['laboratorio'],
      precioNormal: json['precio_normal'],
      precioOferta: json['precio_oferta'],
      precioFinal: json['precio_final'] ?? 0,
      disponible: json['disponible'] ?? false,
      requiereReceta: json['requiere_receta'],
      despachoDomicilio: json['despacho_domicilio'],
      retiroTienda: json['retiro_tienda'],
      esBioequivalente: json['es_bioequivalente'],
      imagenUrl: json['imagen_url'],
      urlProducto: json['url_producto'],
    );
  }
}

/// Un item cotizado -- el producto puede ser null si no se encontro
/// ningun candidato disponible en esta farmacia.
class ItemCotizado {
  final String principioActivo;
  final String? presentacionSolicitada;
  final ProductoCotizado? producto;
  final bool encontrado;

  ItemCotizado({
    required this.principioActivo,
    this.presentacionSolicitada,
    this.producto,
    required this.encontrado,
  });

  factory ItemCotizado.fromJson(Map<String, dynamic> json) {
    return ItemCotizado(
      principioActivo: json['principio_activo'] ?? '',
      presentacionSolicitada: json['presentacion_solicitada'],
      producto: json['producto'] != null
          ? ProductoCotizado.fromJson(json['producto'])
          : null,
      encontrado: json['encontrado'] ?? false,
    );
  }

  bool get sinProducto => producto == null;
}

/// Una farmacia cotizada: sus items (cada uno con el producto mas
/// barato disponible) y el total sumado.
class FarmaciaCotizada {
  final String farmacia;
  final bool completo;
  final List<String> itemsNoEncontrados;
  final List<ItemCotizado> items;
  final int total;

  FarmaciaCotizada({
    required this.farmacia,
    required this.completo,
    required this.itemsNoEncontrados,
    required this.items,
    required this.total,
  });

  factory FarmaciaCotizada.fromJson(Map<String, dynamic> json) {
    return FarmaciaCotizada(
      farmacia: json['farmacia'] ?? '',
      completo: json['completo'] ?? false,
      itemsNoEncontrados: List<String>.from(json['items_no_encontrados'] ?? []),
      items: (json['items'] as List? ?? [])
          .map((i) => ItemCotizado.fromJson(i))
          .toList(),
      total: json['total'] ?? 0,
    );
  }
}

/// Respuesta completa de POST /api/cotizador/cotizar.
class CotizacionResultado {
  final List<ItemReceta> receta;
  final List<FarmaciaCotizada> farmacias;

  CotizacionResultado({required this.receta, required this.farmacias});

  factory CotizacionResultado.fromJson(Map<String, dynamic> json) {
    return CotizacionResultado(
      receta: (json['receta'] as List? ?? [])
          .map((r) => ItemReceta(
                principioActivo: r['principio_activo'] ?? '',
                presentacion: r['presentacion'],
              ))
          .toList(),
      farmacias: (json['farmacias'] as List? ?? [])
          .map((f) => FarmaciaCotizada.fromJson(f))
          .toList(),
    );
  }

  /// Nombre de la farmacia con el total mas bajo, para destacarla en
  /// la UI ("Mas economica").
  String? get farmaciaMasBarata {
    if (farmacias.isEmpty) return null;
    final ordenadas = [...farmacias]..sort((a, b) => a.total.compareTo(b.total));
    return ordenadas.first.farmacia;
  }
}
