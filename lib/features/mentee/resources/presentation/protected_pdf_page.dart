import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdfrx/pdfrx.dart';
import '../../../../core/audio/read_aloud_controller.dart';
import '../../../../core/security/file_vault.dart';
import '../../../../core/storage/secure_storage_provider.dart';
import '../../../../core/widgets/read_aloud_bar.dart';
import '../data/pdf_text.dart';

/// Shows a downloaded PDF inside the app. The file is decrypted into memory
/// only; no readable copy is ever written to the phone. Includes read-aloud.
class ProtectedPdfPage extends ConsumerStatefulWidget {
  const ProtectedPdfPage({
    super.key,
    required this.title,
    this.encryptedPath,
    this.bytes,
    this.resourceId,
  });

  final String title;
  final String? encryptedPath; // a downloaded (encrypted) file
  final Uint8List? bytes; // or a PDF streamed into memory
  final String? resourceId;

  @override
  ConsumerState<ProtectedPdfPage> createState() => _ProtectedPdfPageState();
}

class _ProtectedPdfPageState extends ConsumerState<ProtectedPdfPage> {
  Uint8List? _bytes;
  ReadAloudController? _reader;
  String? _error;

  /// Identifies this document for saving the reading position (the stored
  /// file is named `resource_id.enc`).
  String get _resourceKey {
    if (widget.resourceId != null) return 'pdf:${widget.resourceId}';
    final name = widget.encryptedPath!.replaceAll('\\', '/').split('/').last;
    return 'pdf:${name.endsWith('.enc') ? name.substring(0, name.length - 4) : name}';
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final bytes = widget.bytes ??
          await ref.read(fileVaultProvider).decryptFile(widget.encryptedPath!);
      if (!mounted) return;
      setState(() {
        _bytes = bytes;
        _reader = ReadAloudController(
          loadText: () => extractPdfText(bytes),
          storage: ref.read(secureStorageProvider),
          resourceKey: _resourceKey,
        );
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _error =
          'This file could not be opened. Remove the download and download it again.');
    }
  }

  @override
  void dispose() {
    _reader?.dispose();
    _bytes = null; // let the decrypted copy be collected
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    final reader = _reader;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: Text(widget.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : bytes == null
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    Expanded(
                      child: PdfViewer.data(
                        bytes,
                        sourceName: 'protected:${widget.title}',
                      ),
                    ),
                    if (reader != null) ReadAloudBar(reader: reader),
                  ],
                ),
    );
  }
}
