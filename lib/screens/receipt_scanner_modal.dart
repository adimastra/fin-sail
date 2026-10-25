import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../config/theme.dart';
import '../providers/expense_provider.dart';
import 'review_receipt_screen.dart';

class ReceiptScannerModal extends StatefulWidget {
  const ReceiptScannerModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ReceiptScannerModal(),
    );
  }

  @override
  State<ReceiptScannerModal> createState() => _ReceiptScannerModalState();
}

class _ReceiptScannerModalState extends State<ReceiptScannerModal> with SingleTickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  Uint8List? _previewBytes;
  bool _isAnalyzing = false;
  String _statusMessage = 'Align receipt in viewfinder';

  late AnimationController _scanAnimController;
  late Animation<double> _scanAnimation;

  @override
  void initState() {
    super.initState();
    _scanAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _scanAnimation = Tween<double>(begin: 0.05, end: 0.95).animate(
      CurvedAnimation(parent: _scanAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _scanAnimController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? file = await _picker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (file != null) {
        final bytes = await file.readAsBytes();
        setState(() {
          _previewBytes = bytes;
        });
        _processReceipt(bytes, file.name);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not access camera/file: $e')),
        );
      }
    }
  }

  void _useSampleReceipt() {
    // Generate simulated byte array for immediate testing without file picker
    final sampleBytes = Uint8List.fromList(List.generate(2048, (i) => (i * 7) % 256));
    setState(() {
      _previewBytes = sampleBytes;
    });
    _processReceipt(sampleBytes, 'sample_market_receipt.jpg');
  }

  Future<void> _processReceipt(Uint8List bytes, String filename) async {
    setState(() {
      _isAnalyzing = true;
      _statusMessage = 'Uploading to secure storage...';
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    setState(() {
      _statusMessage = 'AI Vision parsing receipt fields...';
    });

    final provider = context.read<ExpenseProvider>();
    final parsedData = await provider.scanAndExtractReceipt(
      imageBytes: bytes,
      filename: filename,
    );

    if (!mounted) return;

    if (parsedData != null) {
      Navigator.of(context).pop(); // Close scanner sheet
      // Navigate to Review Screen
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (ctx) => ReviewReceiptScreen(
            receiptData: parsedData,
            imageBytes: bytes,
          ),
        ),
      );
    } else {
      setState(() {
        _isAnalyzing = false;
        _statusMessage = 'Analysis failed. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.darkBackground : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(
          color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top bar: drag handle in center, close icon button at right top alone
          Padding(
            padding: const EdgeInsets.only(top: 12, left: 24, right: 20),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white24 : Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 20,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppTheme.receiptScannerGradient,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.document_scanner, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Scan Receipt',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -0.3,
                        ),
                      ),
                      Text(
                        'Auto-extract merchant, total & items',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Viewfinder / Preview Body
          Padding(
            padding: const EdgeInsets.all(20),
            child: AspectRatio(
              aspectRatio: 4 / 4.2,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _isAnalyzing ? AppTheme.secondary : AppTheme.darkBorder,
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Viewfinder border brackets
                      if (!_isAnalyzing && _previewBytes == null)
                        Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(18),
                              decoration: BoxDecoration(
                                color: AppTheme.secondary.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.receipt_long_outlined,
                                size: 48,
                                color: AppTheme.secondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Position receipt within frame',
                              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Ensure store name and total are well-lit',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),

                      // Image preview if selected
                      if (_previewBytes != null)
                        Positioned.fill(
                          child: Opacity(
                            opacity: _isAnalyzing ? 0.75 : 1.0,
                            child: Image.memory(
                              _previewBytes!,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),

                      // Animated Laser Scan Bar
                      if (_isAnalyzing)
                        AnimatedBuilder(
                          animation: _scanAnimation,
                          builder: (context, child) {
                            return Positioned(
                              top: _scanAnimation.value * 280,
                              left: 0,
                              right: 0,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [
                                      Colors.transparent,
                                      AppTheme.secondary,
                                      Colors.cyanAccent,
                                      AppTheme.secondary,
                                      Colors.transparent,
                                    ],
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppTheme.secondary.withOpacity(0.8),
                                      blurRadius: 16,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),

                      // Analyzing Status Banner
                      if (_isAnalyzing)
                        Positioned(
                          bottom: 24,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: AppTheme.secondary.withOpacity(0.4)),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const SizedBox(
                                  width: 14,
                                  height: 14,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(AppTheme.secondary),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  _statusMessage,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Action Buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
            child: Column(
              children: [
                Row(
                  children: [
                    // Camera Button
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.camera_alt_outlined, size: 20),
                        label: const Text('Use Camera', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.camera),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Upload / Gallery Button
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? Colors.white : AppTheme.darkBackground,
                          side: BorderSide(color: isDark ? AppTheme.darkBorder : AppTheme.lightBorder),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        icon: const Icon(Icons.photo_library_outlined, size: 20),
                        label: const Text('Choose File', style: TextStyle(fontWeight: FontWeight.bold)),
                        onPressed: _isAnalyzing ? null : () => _pickImage(ImageSource.gallery),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Fast 1-Tap Sample Receipt Button
                TextButton.icon(
                  icon: const Icon(Icons.bolt, color: AppTheme.secondary, size: 18),
                  label: const Text(
                    '⚡ Test with Sample Receipt (1-Tap Demo)',
                    style: TextStyle(
                      color: AppTheme.secondary,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  onPressed: _isAnalyzing ? null : _useSampleReceipt,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
