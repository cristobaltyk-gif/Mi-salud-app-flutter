/// lib/screens/media_ejercicio_screen.dart
///
/// Se abre al tocar una notificación de recordatorio tipo 'ejercicio'
/// (plan de tratamiento domiciliario de kinesiología). Recibe el
/// mediaPath crudo que llegó en el push FCM (ver fcm_service.dart) y
/// arma la URL completa contra el bucket público de Supabase Storage.
/// Muestra la foto o reproduce el video DENTRO de la app — nunca abre
/// un link externo ni el navegador.
library;

import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import '../config/app_config.dart';

const _extensionesVideo = ['.mp4', '.mov', '.webm', '.avi', '.mkv'];

bool _esVideo(String mediaPath) {
  final lower = mediaPath.toLowerCase();
  return _extensionesVideo.any((ext) => lower.endsWith(ext));
}

class MediaEjercicioScreen extends StatelessWidget {
  final String titulo;
  final String cuerpo;
  final String mediaPath;

  const MediaEjercicioScreen({
    super.key,
    required this.titulo,
    required this.cuerpo,
    required this.mediaPath,
  });

  @override
  Widget build(BuildContext context) {
    final url = '${AppConfig.supabaseStoragePublicUrl}/$mediaPath';
    final esVideo = _esVideo(mediaPath);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu ejercicio'),
        backgroundColor: const Color(0xFF0F766E),
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: esVideo
                  ? _VideoEjercicio(url: url)
                  : _FotoEjercicio(url: url),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, -2)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(titulo,
                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF134E4A))),
                  const SizedBox(height: 6),
                  Text(cuerpo, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FotoEjercicio extends StatelessWidget {
  final String url;
  const _FotoEjercicio({required this.url});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.black,
      width: double.infinity,
      child: InteractiveViewer(
        child: Image.network(
          url,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;
            return const Center(child: CircularProgressIndicator(color: Colors.white));
          },
          errorBuilder: (context, error, stackTrace) => const Center(
            child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 64),
          ),
        ),
      ),
    );
  }
}

class _VideoEjercicio extends StatefulWidget {
  final String url;
  const _VideoEjercicio({required this.url});

  @override
  State<_VideoEjercicio> createState() => _VideoEjercicioState();
}

class _VideoEjercicioState extends State<_VideoEjercicio> {
  late final VideoPlayerController _controller;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {});
        _controller.play();
      }).catchError((_) {
        if (!mounted) return;
        setState(() => _error = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(
          child: Icon(Icons.error_outline, color: Colors.white54, size: 64),
        ),
      );
    }

    if (!_controller.value.isInitialized) {
      return const ColoredBox(
        color: Colors.black,
        child: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }

    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: AspectRatio(
          aspectRatio: _controller.value.aspectRatio,
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              VideoPlayer(_controller),
              _ControlesVideo(controller: _controller),
            ],
          ),
        ),
      ),
    );
  }
}

class _ControlesVideo extends StatefulWidget {
  final VideoPlayerController controller;
  const _ControlesVideo({required this.controller});

  @override
  State<_ControlesVideo> createState() => _ControlesVideoState();
}

class _ControlesVideoState extends State<_ControlesVideo> {
  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTick);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTick);
    super.dispose();
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    return GestureDetector(
      onTap: () {
        setState(() => c.value.isPlaying ? c.pause() : c.play());
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!c.value.isPlaying)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: Colors.black45, shape: BoxShape.circle),
              child: const Icon(Icons.play_arrow, color: Colors.white, size: 40),
            ),
          VideoProgressIndicator(c, allowScrubbing: true, padding: const EdgeInsets.all(8)),
        ],
      ),
    );
  }
}
