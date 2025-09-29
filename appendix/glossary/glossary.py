import os
import re
import logging

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

def get_glossario_terms():
    """Legge il file glossario.typ e ritorna una lista di termini ordinati."""
    gloss_terms = []
    try:
        with open("./glossary.typ", "r", encoding="utf-8") as glossario_file:
            content = glossario_file.read()
    except FileNotFoundError:
        logging.error("File glossary.typ non trovato.")
        return gloss_terms

    try:
        _, gloss_section = content.split("//GLOSSARIO", 1)
    except ValueError:
        logging.error("La sezione //GLOSSARIO non è presente nel file.")
        return gloss_terms

    for line in gloss_section.splitlines():
        if line.startswith("== "):
            term = line.removeprefix("== ").lower().split("(")[0].strip()
            gloss_terms.append(term)
    return sorted(gloss_terms, key=len, reverse=True)

def load_file_content(file_path):
    """Legge il contenuto del file specificato."""
    with open(file_path, "r", encoding="utf-8") as f:
        return f.read()

def write_file_content(file_path, content):
    """Scrive il contenuto sul file specificato."""
    with open(file_path, "w", encoding="utf-8") as f:
        f.write(content)

def extract_header_body(content):
    """
    Divide il contenuto in header e body.
    Il body inizia dalla prima occorrenza di '\n='.
    """
    body_start = content.find("\n=")
    if body_start == -1:
        return content, ""
    header = content[:body_start]
    body = content[body_start:]
    return header, body

def replace_terms_in_text(body, terms, file_path):
    """
    Sostituisce i termini non glossati presenti nel testo con il markup #gloss.
    """
    already_glossed = {m.group(1).lower() for m in re.finditer(r'#gloss\[(.*?)\]', body, re.IGNORECASE)}
    terms_to_search = [term for term in terms if term.lower() not in already_glossed]

    # Per ogni termine che non è ancora glossato, esegui una sostituzione condizionata
    for term in terms_to_search:
        pattern = re.compile(r'(?<!#gloss\[)\b(' + re.escape(term) + r')\b(?!\])', re.IGNORECASE)
        
        def replacer(match):
            start = match.start()
            line_start = body.rfind("\n", 0, start) + 1
            line_end = body.find("\n", start)
            if line_end == -1:
                line_end = len(body)
            line = body[line_start:line_end]
            
            if (line.strip().startswith('=') or 
                line.strip().startswith('"') or 
                'link' in line or 
                'https' in line or 
                'issue' in line or
                'docker' in line or
                'git' in line):
                return match.group(0)
            return f"#gloss[{match.group(1)}]"

        body, count = re.subn(pattern, replacer, body, count=1)
        if count > 0:
            logging.info(f"+ Found '{term}' in {file_path}")
    return body

def process_file(file_path, terms):
    """Processa un singolo file eseguendo la sostituzione dei termini."""
    content = load_file_content(file_path)
    header, body = extract_header_body(content)
    if not body:
        return
    new_body = replace_terms_in_text(body, terms, file_path)
    new_content = header + new_body
    write_file_content(file_path, new_content)

def search_files():
    """Cerca i file .typ e li elabora."""
    gloss_terms = get_glossario_terms()
    logging.info(f"Glossary terms: {gloss_terms}")
    
    skip_dirs = {"bibliography", ".github", "config", "glossary", "images", "appendix"}
    for root, dirs, files in os.walk("./../../chapters/"):
        logging.info(f"Searching in {root}")
        dirs[:] = [d for d in dirs if d not in skip_dirs]
        for file in files:
            if file.endswith(".typ"):
                file_path = os.path.join(root, file)
                process_file(file_path, gloss_terms)

if __name__ == "__main__":
    search_files()