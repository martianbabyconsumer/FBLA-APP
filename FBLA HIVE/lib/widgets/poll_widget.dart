import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../repository/post_repository.dart';
import '../providers/auth_service.dart';

class PollWidget extends StatelessWidget {
  const PollWidget({
    super.key,
    required this.poll,
    required this.postId,
  });

  final Poll poll;
  final String postId;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authService = context.read<AuthService>();
    final userId = authService.user?.uid ?? 'guest';
    
    // Check if user has voted
    final userVote = poll.options.firstWhere(
      (opt) => opt.voterIds.contains(userId),
      orElse: () => PollOption(id: '', text: '', voterIds: {}),
    );
    final hasVoted = userVote.id.isNotEmpty;

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.poll,
                  size: 20,
                  color: theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    poll.question,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...poll.options.map((option) {
              final percentage = poll.totalVotes > 0
                  ? (option.voteCount / poll.totalVotes * 100)
                  : 0.0;
              final isSelected = option.id == userVote.id;

              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () {
                    final repo = context.read<PostRepository>();
                    repo.voteOnPoll(postId, option.id, userId);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.outline.withOpacity(0.3),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // Progress bar background
                        if (hasVoted)
                          FractionallySizedBox(
                            widthFactor: percentage / 100,
                            child: Container(
                              height: 48,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? theme.colorScheme.primary.withOpacity(0.2)
                                    : theme.colorScheme.surfaceVariant.withOpacity(0.5),
                                borderRadius: BorderRadius.circular(7),
                              ),
                            ),
                          ),
                        // Option text and vote count
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16.0,
                            vertical: 12.0,
                          ),
                          child: Row(
                            children: [
                              if (isSelected)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8.0),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 20,
                                    color: theme.colorScheme.primary,
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  option.text,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (hasVoted)
                                Text(
                                  '${percentage.toStringAsFixed(0)}%',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
            const SizedBox(height: 4),
            Text(
              '${poll.totalVotes} ${poll.totalVotes == 1 ? "vote" : "votes"}',
              style: TextStyle(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
