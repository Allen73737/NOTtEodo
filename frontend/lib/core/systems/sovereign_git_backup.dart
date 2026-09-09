/// Sovereign Backup to Self-Hosted Repositories
/// Serializes the entire local Sanctuary database into human-readable Markdown files
/// with YAML frontmatter, ensuring permanent zero platform lock-in data sovereignty.
library;
class VaultMarkdownFile {
  final String relativePath;
  final String markdownContent;

  VaultMarkdownFile({required this.relativePath, required this.markdownContent});
}

class SovereignGitBackup {
  static final SovereignGitBackup _instance = SovereignGitBackup._internal();
  factory SovereignGitBackup() => _instance;
  SovereignGitBackup._internal();

  /// Compiles a note entry into a clean YAML frontmatter Markdown document
  VaultMarkdownFile formatNote({
    required String id,
    required String title,
    required String space,
    required String tag,
    required String date,
    required String content,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('id: "$id"');
    buffer.writeln('title: "$title"');
    buffer.writeln('space: "$space"');
    buffer.writeln('tag: "$tag"');
    buffer.writeln('date: "$date"');
    buffer.writeln('curator: "Allen"');
    buffer.writeln('vault: "NOTTeodo Sanctuary"');
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('# $title');
    buffer.writeln();
    buffer.writeln(content);

    final cleanSlug = title.toLowerCase().replaceAll(RegExp(r'[^\w\s-]'), '').replaceAll(RegExp(r'\s+'), '-');
    return VaultMarkdownFile(
      relativePath: 'notes/$space/$cleanSlug.md',
      markdownContent: buffer.toString(),
    );
  }

  /// Compiles task checklist into a Git Markdown Kanban file
  VaultMarkdownFile formatTasksKanban(List<Map<String, dynamic>> tasks) {
    final buffer = StringBuffer();
    buffer.writeln('---');
    buffer.writeln('title: "Sanctuary Master Task Register"');
    buffer.writeln('updated: "${DateTime.now().toIso8601String()}"');
    buffer.writeln('---');
    buffer.writeln();
    buffer.writeln('# Master Sanctuary Tasks\n');

    for (final task in tasks) {
      final done = (task['completed'] == true) ? '[x]' : '[ ]';
      final priority = task['priority'] ?? 'Standard';
      final title = task['title'] ?? 'Untitled';
      buffer.writeln('- $done **[$priority]** $title');
    }

    return VaultMarkdownFile(
      relativePath: 'tasks/master_kanban.md',
      markdownContent: buffer.toString(),
    );
  }

  /// Bundles all files into a structured JSON manifest ready for Git commit / push
  Map<String, dynamic> generateGitCommitBundle({
    required List<VaultMarkdownFile> files,
    required String commitMessage,
  }) {
    final fileMap = <String, String>{};
    for (final f in files) {
      fileMap[f.relativePath] = f.markdownContent;
    }

    return {
      'commitMessage': commitMessage,
      'branch': 'main',
      'timestamp': DateTime.now().toIso8601String(),
      'tree': fileMap,
    };
  }
}
