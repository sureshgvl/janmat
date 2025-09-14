import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../models/candidate_model.dart';
import '../../../utils/symbol_utils.dart';

class ProfileTabView extends StatefulWidget {
  final Candidate candidate;
  final bool isOwnProfile;
  final bool showVoterInteractions; // New parameter to control voter interactions

  const ProfileTabView({
    Key? key,
    required this.candidate,
    this.isOwnProfile = false,
    this.showVoterInteractions = true, // Default to true for backward compatibility
  }) : super(key: key);

  @override
  State<ProfileTabView> createState() => _ProfileTabViewState();
}

class _ProfileTabViewState extends State<ProfileTabView> with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // Like functionality state
  bool _isProfileLiked = false;
  int _profileLikes = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with some mock data - in real app this would come from server
    _profileLikes = widget.candidate.followersCount ?? 0;
  }

  void _toggleProfileLike() {
    setState(() {
      _isProfileLiked = !_isProfileLiked;
      _profileLikes += _isProfileLiked ? 1 : -1;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isProfileLiked ? 'Profile liked!' : 'Profile unliked'),
        duration: const Duration(seconds: 1),
      ),
    );
  }

  void _shareProfile() async {
    final profileText = '''
Check out ${widget.candidate.name}'s profile!

${widget.candidate.party.isNotEmpty ? 'Party: ${widget.candidate.party}' : 'Independent Candidate'}
Location: ${widget.candidate.districtId}, ${widget.candidate.wardId}

View their complete profile and manifesto at: [Your App URL]
''';

    // For now, just show a snackbar - in real app you'd use share_plus or url_launcher
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Share functionality would open native share dialog'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Header
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.grey.shade200),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                // Profile Photo and Basic Info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: widget.candidate.photo != null
                          ? NetworkImage(widget.candidate.photo!)
                          : null,
                      child: widget.candidate.photo == null
                          ? Text(
                              widget.candidate.name[0].toUpperCase(),
                              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.candidate.name,
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1f2937),
                                  ),
                                ),
                              ),
                              // Like Count - Always visible (even for own profile)
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: Colors.red.shade200),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.favorite,
                                      size: 16,
                                      color: Colors.red.shade600,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _profileLikes.toString(),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    if (_profileLikes == 1)
                                      Text(
                                        ' Like',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      )
                                    else
                                      Text(
                                        ' Likes',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.grey[600],
                                        ),
                                      ),
                                  ],
                                ),
                              ),

                              // Interactive Like and Share buttons - Only for voters
                              if (widget.showVoterInteractions) ...[
                                const SizedBox(width: 8),
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    // Like Button
                                    GestureDetector(
                                      onTap: _toggleProfileLike,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: _isProfileLiked ? Colors.red.shade50 : Colors.grey.shade50,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(
                                            color: _isProfileLiked ? Colors.red.shade200 : Colors.grey.shade300,
                                          ),
                                        ),
                                        child: Icon(
                                          _isProfileLiked ? Icons.favorite : Icons.favorite_border,
                                          size: 16,
                                          color: _isProfileLiked ? Colors.red : Colors.grey[600],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // Share Button
                                    GestureDetector(
                                      onTap: _shareProfile,
                                      child: Container(
                                        padding: const EdgeInsets.all(8),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade50,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.blue.shade200),
                                        ),
                                        child: const Icon(
                                          Icons.share,
                                          size: 16,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              if (widget.candidate.party.toLowerCase().contains('independent') || widget.candidate.party.trim().isEmpty)
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey.shade200,
                                  ),
                                  child: const Icon(
                                    Icons.label,
                                    size: 24,
                                    color: Colors.grey,
                                  ),
                                )
                              else
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    image: DecorationImage(
                                      image: SymbolUtils.getSymbolImageProvider(
                                        SymbolUtils.getPartySymbolPath(widget.candidate.party, candidate: widget.candidate)
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      widget.candidate.party.toLowerCase().contains('independent') || widget.candidate.party.trim().isEmpty
                                          ? 'Independent Candidate'
                                          : widget.candidate.party,
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: widget.candidate.party.toLowerCase().contains('independent') || widget.candidate.party.trim().isEmpty
                                            ? Colors.grey.shade700
                                            : Colors.blue,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    if (widget.candidate.symbol != null && widget.candidate.symbol!.isNotEmpty)
                                      Text(
                                        'Symbol: ${widget.candidate.symbol}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Basic Information Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.person_outline,
                        color: Colors.blue.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Basic Information',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Age and Gender
                if (widget.candidate.extraInfo?.basicInfo?.age != null ||
                    widget.candidate.extraInfo?.basicInfo?.gender != null) ...[
                  Row(
                    children: [
                      if (widget.candidate.extraInfo?.basicInfo?.age != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.purple.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.purple.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Age',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.purple.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${widget.candidate.extraInfo!.basicInfo!.age}',
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1f2937),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (widget.candidate.extraInfo?.basicInfo?.age != null &&
                          widget.candidate.extraInfo?.basicInfo?.gender != null)
                        const SizedBox(width: 12),
                      if (widget.candidate.extraInfo?.basicInfo?.gender != null)
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.green.shade50,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.green.shade200),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Gender',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.candidate.extraInfo!.basicInfo!.gender!,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF1f2937),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                ],

                // Education
                if (widget.candidate.extraInfo?.basicInfo?.education != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Education',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.candidate.extraInfo!.basicInfo!.education!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1f2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Address
                if (widget.candidate.extraInfo?.contact?.address != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.teal.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.teal.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Address',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.teal.shade600,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          widget.candidate.extraInfo!.contact!.address!,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF1f2937),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Location Information
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.location_on_outlined,
                        color: Colors.red.shade600,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1f2937),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.indigo.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.indigo.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'District',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.indigo.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.candidate.districtId,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1f2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.pink.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.pink.shade200),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ward',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.pink.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              widget.candidate.wardId,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1f2937),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
