import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../l10n/features/candidate/candidate_localizations.dart';
import '../../../../services/manifesto_comments_service.dart';
import '../../../../services/manifesto_likes_service.dart';
import '../../../../models/comment_model.dart';

class ManifestoCommentsSection extends StatefulWidget {
  final String? manifestoId;
  final String? currentUserId;

  const ManifestoCommentsSection({
    super.key,
    required this.manifestoId,
    required this.currentUserId,
  });

  @override
  State<ManifestoCommentsSection> createState() => _ManifestoCommentsSectionState();
}

class _ManifestoCommentsSectionState extends State<ManifestoCommentsSection> {
  final TextEditingController _commentController = TextEditingController();
  final TextEditingController _replyController = TextEditingController();
  bool _showComments = false;
  String? _replyingToCommentId;
  bool _isCommentLoading = false;
  String? _commentError;
  Stream<List<CommentModel>>? _commentsStream;

  @override
  void initState() {
    super.initState();
    if (widget.manifestoId != null && widget.currentUserId != null) {
      _commentsStream = ManifestoCommentsService.getComments(widget.manifestoId!);
    }
  }

  @override
  void dispose() {
    _commentController.dispose();
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _addComment({String? parentId}) async {
    if (widget.currentUserId == null) {
      Get.snackbar(
        'error'.tr,
        'pleaseLoginToInteract'.tr,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    final controller = parentId != null ? _replyController : _commentController;
    if (controller.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('pleaseEnterComment'.tr, overflow: TextOverflow.ellipsis),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    if (widget.manifestoId == null) return;

    setState(() {
      _isCommentLoading = true;
      _commentError = null;
    });

    try {
      await ManifestoCommentsService.addComment(
        widget.currentUserId!,
        widget.manifestoId!,
        controller.text.trim(),
        parentId: parentId,
      );

      controller.clear();
      if (parentId != null) {
        setState(() {
          _replyingToCommentId = null;
        });
      }

      // Award XP for commenting
      Get.snackbar(
        'xpEarned'.tr,
        CandidateTranslations.tr('earnedXpForCommenting', args: {'count': '5'}),
        backgroundColor: Colors.blue.shade100,
        colorText: Colors.blue.shade800,
        duration: const Duration(seconds: 2),
        maxWidth: 300,
      );
    } catch (e) {
      setState(() {
        _commentError = e.toString();
      });
      Get.snackbar(
        'error'.tr,
        'failedToAddComment'.tr,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    } finally {
      setState(() {
        _isCommentLoading = false;
      });
    }
  }

  Future<void> _toggleCommentLike(String commentId) async {
    if (widget.currentUserId == null) {
      Get.snackbar(
        'error'.tr,
        'pleaseLoginToInteract'.tr,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
      return;
    }

    try {
      await ManifestoCommentsService.toggleCommentLike(widget.currentUserId!, commentId);
    } catch (e) {
      Get.snackbar(
        'error'.tr,
        'failedToUpdateCommentLike'.tr,
        backgroundColor: Colors.red.shade100,
        colorText: Colors.red.shade800,
      );
    }
  }

  void _toggleCommentsVisibility() {
    setState(() {
      _showComments = !_showComments;
    });
  }

  void _startReply(String commentId) {
    setState(() {
      _replyingToCommentId = commentId;
      _replyController.clear();
    });
  }

  String _formatCommentTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  List<Widget> _buildThreadedComments(List<CommentModel> comments) {
    final topLevelComments = comments.where((c) => c.parentId == null).toList();
    final replies = comments.where((c) => c.parentId != null).toList();

    final List<Widget> widgets = [];

    for (final comment in topLevelComments) {
      widgets.add(_buildCommentWidget(comment, 0));
      final commentReplies = replies.where((r) => r.parentId == comment.id).toList();
      for (final reply in commentReplies) {
        widgets.add(_buildCommentWidget(reply, 1));
      }
    }

    return widgets;
  }

  Widget _buildCommentWidget(CommentModel comment, int depth) {
    final isReplyingToThis = _replyingToCommentId == comment.id;

    return Container(
      margin: EdgeInsets.only(bottom: 12, left: depth * 32.0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 16,
                backgroundColor: Colors.blue,
                child: Icon(
                  Icons.person,
                  size: 16,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'anonymousVoter'.tr,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Color(0xFF374151),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Flexible(
                child: Text(
                  _formatCommentTime(comment.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            comment.text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Color(0xFF374151),
            ),
            overflow: TextOverflow.ellipsis,
            maxLines: 3,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Flexible(
                child: StreamBuilder<int>(
                  stream: ManifestoLikesService.getLikeCountStream(comment.id),
                  builder: (context, likeSnapshot) {
                    final likeCount = likeSnapshot.data ?? 0;
                    return StreamBuilder<bool>(
                      stream: Stream.fromFuture(
                        widget.currentUserId != null
                            ? ManifestoLikesService.hasUserLiked(widget.currentUserId!, comment.id)
                            : Future.value(false)
                      ),
                      builder: (context, userLikeSnapshot) {
                        final isLiked = userLikeSnapshot.data ?? false;
                        return GestureDetector(
                          onTap: () => _toggleCommentLike(comment.id),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isLiked ? Icons.favorite : Icons.favorite_border,
                                size: 16,
                                color: isLiked ? Colors.red : Colors.grey,
                              ),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  '$likeCount',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
              const SizedBox(width: 16),
              Flexible(
                child: GestureDetector(
                  onTap: () => _startReply(comment.id),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.reply,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          'reply'.tr,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (isReplyingToThis) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                children: [
                  TextField(
                    controller: _replyController,
                    maxLines: 3,
                    maxLength: 500,
                    decoration: InputDecoration(
                      hintText: 'writeAReply'.tr,
                      border: InputBorder.none,
                      counterText: '',
                      hintStyle: TextStyle(fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Flexible(
                        child: TextButton(
                          onPressed: _isCommentLoading ? null : () {
                            setState(() {
                              _replyingToCommentId = null;
                            });
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.grey,
                          ),
                          child: Text('cancel'.tr, overflow: TextOverflow.ellipsis),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: ElevatedButton.icon(
                          onPressed: _isCommentLoading ? null : () => _addComment(parentId: comment.id),
                          icon: _isCommentLoading
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Icon(Icons.send, size: 16),
                          label: Text(
                            _isCommentLoading ? 'posting'.tr : 'postReply'.tr,
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _isCommentLoading ? Colors.grey : Colors.blue.shade600,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Comments Section Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                CandidateTranslations.tr('comments'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            InkWell(
              onTap: _toggleCommentsVisibility,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _showComments
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    size: 16,
                    color: Colors.blue.shade600,
                  ),
                  const SizedBox(width: 4),
                  if (_commentsStream != null)
                    StreamBuilder<List<CommentModel>>(
                      stream: _commentsStream,
                      builder: (context, snapshot) {
                        final commentsCount = snapshot.data?.length ?? 0;
                        return Text(
                          _showComments
                              ? CandidateTranslations.tr('hideComments')
                              : '$commentsCount',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.blue.shade600,
                          ),
                        );
                      },
                    )
                  else
                    Text(
                      _showComments
                          ? CandidateTranslations.tr('hideComments')
                          : '0',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade600,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // Add Comment Input
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Column(
            children: [
              TextField(
                controller: _commentController,
                maxLines: 3,
                maxLength: 500,
                decoration: InputDecoration(
                  hintText: 'shareYourThoughts'.tr,
                  border: InputBorder.none,
                  counterText: '',
                  hintStyle: TextStyle(fontSize: 10),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Flexible(
                    child: TextButton(
                      onPressed: _isCommentLoading ? null : () => _commentController.clear(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey,
                      ),
                      child: Text('cancel'.tr, overflow: TextOverflow.ellipsis),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: ElevatedButton.icon(
                      onPressed: _isCommentLoading ? null : _addComment,
                      icon: _isCommentLoading
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Icon(Icons.send, size: 16),
                      label: Text(
                        _isCommentLoading ? 'posting'.tr : 'postComment'.tr,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isCommentLoading ? Colors.grey : Colors.blue.shade600,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Comments List
        if (_showComments) ...[
          if (_commentsStream != null)
            StreamBuilder<List<CommentModel>>(
              stream: _commentsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: const Center(
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'failedToLoadComments'.tr,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.red,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                final comments = snapshot.data ?? [];

                if (comments.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'noCommentsYet'.tr,
                        style: const TextStyle(
                          fontSize: 10,
                          color: Colors.grey,
                          fontStyle: FontStyle.italic,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }

                return Column(
                  children: _buildThreadedComments(comments),
                );
              },
            )
          else
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'commentsNotAvailable'.tr,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          if (_commentError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                _commentError!,
                style: const TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ],
    );
  }
}