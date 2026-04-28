import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../const.dart';
import '../viewmodels/auth_viewmodel.dart';

class LinkRequestCard extends StatelessWidget {
  final String currentUserId;

  const LinkRequestCard({super.key, required this.currentUserId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('linkRequests')
          .where('toUserId', isEqualTo: currentUserId)
          .snapshots(),
      builder: (context, snapshot) {
        final docs =
            snapshot.data?.docs.where((doc) {
              return doc.data()['status'] == 'pending';
            }).toList() ??
            [];

        if (docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final request = docs.first;
        final data = request.data();

        final fromName = data['fromName'] ?? 'User';
        final fromEmail = data['fromEmail'] ?? '';
        final fromRole = data['fromRole'] ?? '';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kAccent.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.link_rounded, color: kAccent),
                  SizedBox(width: 8),
                  Text(
                    "New Link Request",
                    style: TextStyle(
                      color: kText,
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              Text(
                "$fromName wants to connect with you.",
                style: const TextStyle(
                  color: kText,
                  fontWeight: FontWeight.w800,
                ),
              ),

              const SizedBox(height: 4),

              Text(
                "$fromEmail • $fromRole",
                style: const TextStyle(color: kText2, fontSize: 13),
              ),

              const SizedBox(height: 14),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AuthViewModel>().acceptLinkRequest(
                          requestId: request.id,
                        );
                      },
                      icon: const Icon(Icons.check_rounded),
                      label: const Text("Accept"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 10),

                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        context.read<AuthViewModel>().declineLinkRequest(
                          requestId: request.id,
                        );
                      },
                      icon: const Icon(Icons.close_rounded),
                      label: const Text("Decline"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
