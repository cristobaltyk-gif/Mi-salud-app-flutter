/// lib/models/cotizacion.dart
///
/// Modelos que reflejan exactamente el JSON que devuelve
/// cotizador_service.py -> cotizar_receta() en el backend, expuesto via
/// POST /api/cotizador/cotizar (cotizador_router.py).
///
/// Sin fallback entre niveles (v2 del backend, 03-08-2026): un
/// ProductoCotizado puede ser null en un nivel especifico si no hay
/// candidato con ese nivel de confianza de laboratorio para ese item --
/// eso es intencional, no un error a manejar como excepcion.
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

/// Un producto especifico encontrado en una farmacia (puede ser null si
/// no hay candidato para ese nivel de confianza).
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

/// Un item dentro de un nivel de paquete -- el producto puede ser null
/// (no encontrado en la farmacia, o sin candidato en este nivel exacto).
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

  /// true si este item no tiene producto para mostrar, sin importar el
  /// motivo exacto (no encontrado en la farmacia, o sin candidato en
  /// este nivel de confianza especifico).
  bool get sinProducto => producto == null;
}

/// Un nivel de paquete (economico | intermedio | premium) para una
/// farmacia: sus items y el total (solo de los items que si tuvieron
/// producto en este nivel).
class NivelPaquete {
  final List<ItemCotizado> items;
  final int total;
  final List<String> itemsFaltantesNivel;

  NivelPaquete({
    required this.items,
    required this.total,
    required this.itemsFaltantesNivel,
  });

  factory NivelPaquete.fromJson(Map<String, dynamic> json) {
    return NivelPaquete(
      items: (json['items'] as List? ?? [])
          .map((i) => ItemCotizado.fromJson(i))
          .toList(),
      total: json['total'] ?? 0,
      itemsFaltantesNivel:
          List<String>.from(json['items_faltantes_nivel'] ?? []),
    );
  }
}

/// Una farmacia cotizada, con sus 3 niveles.
class FarmaciaCotizada {
  final String farmacia;
  final bool completo;
  final List<String> itemsNoEncontrados;
  final NivelPaquete economico;
  final NivelPaquete intermedio;
  final NivelPaquete premium;

  FarmaciaCotizada({
    required this.farmacia,
    required this.completo,
    required this.itemsNoEncontrados,
    required this.economico,
    required this.intermedio,
    required this.premium,
  });

  factory FarmaciaCotizada.fromJson(Map<String, dynamic> json) {
    final niveles = json['niveles'] as Map<String, dynamic>;
    return FarmaciaCotizada(
      farmacia: json['farmacia'] ?? '',
      completo: json['completo'] ?? false,
      itemsNoEncontrados: List<String>.from(json['items_no_encontrados'] ?? []),
      economico: NivelPaquete.fromJson(niveles['economico']),
      intermedio: NivelPaquete.fromJson(niveles['intermedio']),
      premium: NivelPaquete.fromJson(niveles['premium']),
    );
  }

  NivelPaquete porNombre(String nivel) {
    switch (nivel) {
      case 'intermedio':
        return intermedio;
      case 'premium':
        return premium;
      case 'economico':
      default:
        return economico;
    }
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

  /// Nombre de la farmacia con el total mas bajo en nivel economico,
  /// para destacarla en la UI ("Mas economica").
  String? get farmaciaMasBarata {
    if (farmacias.isEmpty) return null;
    final ordenadas = [...farmacias]
      ..sort((a, b) => a.economico.total.compareTo(b.economico.total));
    return ordenadas.first.farmacia;
  }
}
