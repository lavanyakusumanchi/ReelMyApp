import 'package:flutter/material.dart';
import '../../models/reel.dart';
import '../../widgets/video_reel_item.dart';

import 'package:provider/provider.dart';
import '../../providers/admin_provider.dart';
import '../../providers/auth_provider.dart';

class AdminReelViewer extends StatefulWidget {
  final Reel reel;

  const AdminReelViewer({super.key, required this.reel});

  @override
  State<AdminReelViewer> createState() => _AdminReelViewerState();
}

class _AdminReelViewerState extends State<AdminReelViewer> {
  
  void _manageReel(String action) async {
    // 🛡️ Sanitize ID
    String reelId = widget.reel.id;
    if (reelId.contains('_')) {
      reelId = reelId.split('_')[0];
    }
    // Aggressive Fix: MongoDB ObjectIDs are 24 chars
    if (reelId.length > 24) {
      print("⚠️ [AdminReelViewer] Truncating ID: $reelId -> ${reelId.substring(0, 24)}");
      reelId = reelId.substring(0, 24);
    }
    
    // Show Confirmation
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${action[0].toUpperCase()}${action.substring(1)} Reel?'),
        content: Text('Are you sure you want to $action this reel?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: action == 'delete' ? Colors.red : Colors.blue),
            child: const Text('Confirm'),
          )
        ],
      )
    );

    if (confirm != true) return;

    if (!mounted) return;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const Center(child: CircularProgressIndicator())
    );

    final token = Provider.of<AuthProvider>(context, listen: false).token;
    bool success = false;
    String? errorMsg;

    if (token != null) {
      final provider = Provider.of<AdminProvider>(context, listen: false);
      success = await provider.manageReel(reelId, action, token);
      errorMsg = provider.error;
    }

    if (!mounted) return;
    Navigator.pop(context); // Close loading

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reel $action success!'), backgroundColor: Colors.green)
      );
      Navigator.pop(context); // Exit viewer on delete/reject
    } else {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Error'),
          content: Text('Failed to $action reel.\nError: ${errorMsg ?? "Unknown"}'),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
        )
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // The Reel Player
          Positioned.fill(
            child: VideoReelItem(
              reel: widget.reel,
              isVisible: true,
              shouldPreload: true,
            ),
          ),

          // Close Button (Top Left)
          Positioned(
            top: 40,
            left: 16,
            child: CircleAvatar(
              backgroundColor: Colors.black54,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),

          // Admin Controls (Top Right)
          Positioned(
            top: 40,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.cancel, color: Colors.redAccent),
                    tooltip: 'Reject',
                    onPressed: () => _manageReel('reject'),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                     icon: const Icon(Icons.delete, color: Colors.red),
                     tooltip: 'Delete',
                     onPressed: () => _manageReel('delete'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
