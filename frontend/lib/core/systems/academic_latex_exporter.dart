/// Automated Markdown / LaTeX / BibTeX Academic Exporter
/// Converts curated notes and research journals into professional,
/// publication-ready LaTeX documents and BibTeX bibliography databases.
library;

class AcademicLatexExporter {
  static final AcademicLatexExporter _instance = AcademicLatexExporter._internal();
  factory AcademicLatexExporter() => _instance;
  AcademicLatexExporter._internal();

  /// Converts note title, author, date, and markdown body to LaTeX document source
  String exportToLatex({
    required String title,
    required String author,
    required String content,
    List<String> tags = const [],
  }) {
    final sanitizedContent = content
        .replaceAll('&', r'\&')
        .replaceAll('%', r'\%')
        .replaceAll('#', r'\#')
        .replaceAll('_', r'\_');

    return '''
\\documentclass[11pt,a4paper]{article}
\\usepackage[utf8]{inputenc}
\\usepackage{amsmath,amssymb}
\\usepackage{booktabs}
\\usepackage{hyperref}
\\usepackage{geometry}
\\geometry{margin=1in}

\\title{\\textbf{$title}}
\\author{$author}
\\date{\\today}

\\begin{document}
\\maketitle

\\begin{abstract}
Curated within NOTTeodo Sanctuary. Tags: ${tags.join(', ')}.
\\end{abstract}

\\section{Curator Discourse}
$sanitizedContent

\\bibliographystyle{plain}
\\bibliography{references}
\\end{document}
''';
  }

  /// Generates a BibTeX citation entry for a curated note or book reference
  String generateBibtex({
    required String key,
    required String title,
    required String author,
    required int year,
    String? url,
  }) {
    return '''
@misc{$key,
  author = {$author},
  title = {$title},
  year = {$year},
  howpublished = {NOTTeodo Sanctuary Archive},
  note = {Offline Local-First Vault}
}
''';
  }
}
