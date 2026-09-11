import os

path = "lib/src/features/meets/presentation/meets_screen.dart"
with open(path, "r") as f:
    text = f.read()

# Add Container Wrapper and apply dark theme styling to MeetsScreen
text = text.replace(
    '''    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Upcoming Meets', style: GoogleFonts.outfit()),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,''',
    '''    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF001B33), Color(0xFF000B1A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: Text('Upcoming Meets', style: GoogleFonts.outfit(color: Colors.white)),
          centerTitle: true,
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: const BackButton(color: Colors.white),'''
)

# Text colors
text = text.replace("color: const Color(0xFF0F172A)", "color: Colors.white")
text = text.replace("color: const Color(0xFF64748B)", "color: Colors.white70")
text = text.replace("color: const Color(0xFF94A3B8)", "color: Colors.white54")
text = text.replace("color: Colors.grey[700]", "color: Colors.white")
text = text.replace("color: Colors.grey[600]", "color: Colors.white70")
text = text.replace("color: Colors.grey[400]", "color: Colors.white54")

# Update MeetsScreen scaffold ending
text = text.replace(
    '''      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show Add Meet Dialog
        },
        child: const Icon(Icons.add),
      ),
    );
  }''',
    '''      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Show Add Meet Dialog
        },
        child: const Icon(Icons.add),
      ),
    ),
    );
  }'''
)

with open(path, "w") as f:
    f.write(text)
print("Finished fixing meets_screen.dart")
