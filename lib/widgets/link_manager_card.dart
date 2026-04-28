import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../const.dart';
import '../viewmodels/auth_viewmodel.dart';

class LinkManagerCard extends StatefulWidget {
  final String currentUserId;

  const LinkManagerCard({super.key, required this.currentUserId});

  @override
  State<LinkManagerCard> createState() => _LinkManagerCardState();
}

class _LinkManagerCardState extends State<LinkManagerCard> {
  final emailController = TextEditingController();

  @override
  void dispose() {
    emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();
    final user = authVm.currentUser;

    if (user == null) return const SizedBox.shrink();

    if (user.linkStatus == 'connected') {
      return _connectedCard(context, user.linkedUserEmail ?? '');
    }

    return Column(
      children: [
        _incomingRequest(),
        _outgoingRequest(),
        _sendRequestCard(context),
      ],
    );
  }

  Widget _incomingRequest() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('linkRequests')
          .where('toUserId', isEqualTo: widget.currentUserId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) return const SizedBox.shrink();

        final request = docs.first;
        final data = request.data();

        final fromName = data['fromName'] ?? 'User';
        final fromEmail = data['fromEmail'] ?? '';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: kAccent.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: kAccent.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "New Link Request",
                style: TextStyle(
                  color: kText,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "$fromName wants to connect with you.",
                style: const TextStyle(
                  color: kText,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 4),
              Text(fromEmail, style: const TextStyle(color: kText2)),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        context.read<AuthViewModel>().acceptLinkRequest(
                          requestId: request.id,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccent,
                        foregroundColor: Colors.white,
                        elevation: 0,
                      ),
                      child: const Text("Accept"),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        context.read<AuthViewModel>().declineLinkRequest(
                          requestId: request.id,
                        );
                      },
                      child: const Text("Decline"),
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

  Widget _outgoingRequest() {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('linkRequests')
          .where('fromUserId', isEqualTo: widget.currentUserId)
          .where('status', isEqualTo: 'pending')
          .snapshots(),
      builder: (context, snapshot) {
        final docs = snapshot.data?.docs ?? [];

        if (docs.isEmpty) return const SizedBox.shrink();

        final request = docs.first;
        final data = request.data();

        final toEmail = data['toEmail'] ?? '';

        return Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.orange.withOpacity(0.25)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Pending Request",
                style: TextStyle(
                  color: kText,
                  fontWeight: FontWeight.w900,
                  fontSize: 17,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Waiting for $toEmail to accept your request.",
                style: const TextStyle(color: kText2),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () {
                  context.read<AuthViewModel>().cancelOutgoingLinkRequest(
                    requestId: request.id,
                  );
                },
                icon: const Icon(Icons.close_rounded),
                label: const Text("Cancel Request"),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _sendRequestCard(BuildContext context) {
    final authVm = context.watch<AuthViewModel>();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Link with user",
            style: TextStyle(
              color: kText,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Enter the email of the deaf user or caregiver you want to connect with.",
            style: TextStyle(color: kText2, height: 1.4),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              hintText: "User email",
              filled: true,
              fillColor: kBg,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (authVm.error != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                authVm.error!,
                style: const TextStyle(
                  color: Colors.red,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: authVm.isLoading
                  ? null
                  : () {
                      context.read<AuthViewModel>().sendLinkRequest(
                        emailController.text,
                      );
                      emailController.clear();
                    },
              icon: const Icon(Icons.link_rounded),
              label: const Text("Send Request"),
              style: ElevatedButton.styleFrom(
                backgroundColor: kAccent,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _connectedCard(BuildContext context, String email) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.green.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Connected",
            style: TextStyle(
              color: kText,
              fontWeight: FontWeight.w900,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 6),
          Text(email, style: const TextStyle(color: kText2)),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              context.read<AuthViewModel>().unlinkCurrentUser();
            },
            icon: const Icon(Icons.link_off_rounded),
            label: const Text("Unlink"),
          ),
        ],
      ),
    );
  }
}
