// Copyright 2026 Jonathan de Boyne Pollard
// Public Domain is not a thing in U.K. law, so this is MIT "Expat"/ISC/2 Clause BSD/FreeBSD licenced.
// vim: sts=2 sw=2 et:

#include <unistd.h>
#include <getopt.h>
#include <cstdlib>
#include <cstring>
#include <climits>
#include <cstdint>
#include <cctype>
#include <iostream>
#include <fstream>
#include <string>
#include <map>
#include <vector>
#if defined(__GLIBC__)
#include <endian.h>
#else
#include <sys/endian.h>
#endif

namespace {

  const char version[] = "1.0";

#if !defined(__GLIBC__)
  const char *
  basename (
    const char * pathname
  ) {
    const char * slash(std::strrchr(pathname, '/'));
    return slash ? slash + 1 : pathname;
  }
#endif

  // For long options that have no equivalent short option, use a non-character as a pseudo short option, starting with CHAR_MAX + 1.
  enum
  {
    HELP_OPTION = CHAR_MAX + 1,
    USAGE_OPTION,
    VERSION_OPTION,
  };

  static char const short_options[] = "+w:h:";

  static struct option const long_options[] =
  {
    {"width",   required_argument,  nullptr, 'w'},
    {"height",  required_argument,  nullptr, 'h'},
    {"help",    no_argument,        nullptr, HELP_OPTION},
    {"usage",   no_argument,        nullptr, USAGE_OPTION},
    {"version", no_argument,        nullptr, VERSION_OPTION},
    {nullptr,   0,                  nullptr, 0}
  };

  void
  usage (
    std::ostream & out,
    const char * prog
  ) {
    out << "usage: " << prog;
    /// Assume that every short option has a long option, so do not bother parsing the short_options array.
    for (const struct option * o(long_options); o->name; ++o)
    {
      out << " [--" << o->name;
      if (o->has_arg) out << " arg";
      out.put(']');
    }
    out << " hexfont-normal-file [hexfont-bold-file] vtfont-file";
    out.put('\n');
  }

  /// The header of a vt(4) font file.
  struct [[packed]] vtfont_header
  {
    std::uint8_t	magic[8], width, height;
    std::uint16_t	padding;
    std::uint32_t	glyphs, map_lengths[4];
  };
  static_assert(32U == sizeof(struct vtfont_header), "Font header structure is the wrong length.");

  /// A map entry in a vt(4) font file.
  struct [[packed]] vtfont_map_entry
  {
    std::uint32_t	codepoint;
    std::uint16_t	glyph, count;
  };
  static_assert(8U == sizeof(struct vtfont_map_entry), "Font map entry structure is the wrong length.");
  typedef std::vector<vtfont_map_entry> EntryVector;

  /// \brief The in-memory constructed representation of a VT font.
  struct VTFont
  {
    VTFont(const char * p, unsigned long w, unsigned long h) : width(w), height(h), prog(p), glyphs() {}
    enum { NUM_MAPS = 4U };
    unsigned long width, height;
    bool load(unsigned map, std::istream & in, const char * filename);
    bool save(std::ostream & out, const char * filename);
    static bool bad_width(unsigned long n) { return n < 1U || n > 32U || (n & 3U); }
    static bool bad_height(unsigned long n) { return n < 1U || n > 32U; }
    static const char bad_width_message[], bad_height_message[];
  protected:
    /// \brief A single glyph, possibly the left-hand or right-hand part of a double-width glyph in the HEX file.
    struct Glyph {
      enum { HASH_START = 5831 };
      Glyph() : hash(HASH_START) {}
      std::uint32_t hash;   ///< djb2 hash of all of the rows so far.
      typedef std::vector<std::uint32_t> Rows;
      Rows rows;
      void clear() { hash = HASH_START; rows.clear(); }
      void add_row(uint32_t row, unsigned bytes) {
        for (unsigned i(0U); i < bytes; ++i) {
          const uint8_t v((row >> (i * 8U)) & 0xFF);
          hash += (hash << 5);
          hash ^= v;
        }
        rows.push_back(row);
      }
    };
    typedef std::vector<Glyph> GlyphVector;
    typedef std::multimap<uint32_t, GlyphVector::size_type> GlyphHashIndex;
    typedef std::map<uint_fast32_t, GlyphVector::size_type> CharacterMap;
    const char * const prog;
    GlyphVector glyphs;
    GlyphHashIndex hash_index;  ///< used for de-duplicating glyphs quickly
    CharacterMap maps[NUM_MAPS];
    void error(const char * filename, const char * message);
    void error(const char * filename, unsigned long number, const std::string & line, const std::string::const_iterator & pb, const std::string::const_iterator & pe, const char * message);
    bool get_number_eol(unsigned long & value, std::string::const_iterator & p, const std::string::const_iterator & e, const char * filename, const std::string & line, unsigned long number);
    bool directive(const char * filename, const std::string & line, unsigned long number);
    bool get_codepoint(uint_fast32_t & codepoint, std::string::const_iterator & p, const std::string::const_iterator & e, const char * filename, const std::string & line, unsigned long number);
    bool get_data_eol(Glyph::Rows & rows, std::string::const_iterator & p, const std::string::const_iterator & e, const char * filename, const std::string & line, unsigned long number);
    bool matches(const Glyph & left, const Glyph & right) const;
    GlyphVector::size_type upsert_glyph(const Glyph & glyph);
    bool make_map_entries (EntryVector & entries, const CharacterMap & map, const char * filename);
  };

  inline
  int
  x2d ( int c )
  {
    if (std::isdigit(c))
      return c - '0';
    else if (std::isxdigit(c))
    {
      c = std::tolower(c);
      return c - 'a' + 10;
    } else
      return EOF;
  }

  inline
  bool
  startswith (
    const std::string & s,
    const std::string & prefix
  ) {
    return s.length() >= prefix.length() && s.substr(0, prefix.length()) == prefix;
  }

}

const char VTFont::bad_width_message[] = "Width must be in the range 1 to 32 inclusive, and a multiple of 4.";
const char VTFont::bad_height_message[] = "Height must be in the range 1 to 32 inclusive.";

void
VTFont::error(
  const char * filename,
  const char * message
) {
  std::cerr << prog << ": error: " << filename << ": " << message << '\n';
}

void
VTFont::error(
  const char * filename,
  unsigned long number,
  const std::string & line,
  const std::string::const_iterator & pb, ///< beginning of relevant part of line
  const std::string::const_iterator & pe, ///< end of relevant part of line
  const char * message
) {
  std::cerr << prog << ": error: " << filename << '(' << number << "): " << message << '\n';
  std::string::const_iterator p(pb), b(line.begin());
  if (b != p)
    std::cerr << std::string(b, p);
  const std::string::const_iterator e(line.end());
  if (p != e)
  {
    std::cerr << "\x1b[4m" << std::string(p, pe) << "\x1b[24m";
    ++p;
  }
  if (pe != e)
    std::cerr << std::string(pe, e);
  std::cerr.put('\n');
}

bool                                      /// \return false on a lexing error
VTFont::get_number_eol(
  unsigned long & value,
  std::string::const_iterator & p,        ///< start point to work from, updated on return
  const std::string::const_iterator & e,  ///< end of line, already worked out by the caller
  const char * filename,
  const std::string & line,
  unsigned long number
) {
  const std::string::const_iterator b(p);
  value = 0UL;
  while (e != p && std::isdigit(*p))
  {
    value = value * 10U + (*p - '0');
    ++p;
  }
  if (b == p)
  {
    error(filename, number, line, b, e != b ? b + 1 : b, "Expecting a number.");
    return false;
  }
  if (e != p)
  {
    error(filename, number, line, p, e, "Unexpected extra stuff.");
    return false;
  }
  return true;
}

bool                                      /// \return false on a lexing error
VTFont::directive(
  const char * filename,
  const std::string & line,
  unsigned long number
) {
  static const std::string height_directive("# Height: "), width_directive("# Width: ");
  if (startswith(line, height_directive))
  {
    std::string::const_iterator p(line.begin() + height_directive.length());
    const std::string::const_iterator & e(line.end()), b(p);
    unsigned long new_height;
    if (!get_number_eol(new_height, p, e, filename, line, number))
      return false;
    if (bad_height(new_height))
    {
      error(filename, number, line, b, p, bad_height_message);
      return false;
    }
    if (glyphs.size() && height != new_height)
    {
      error(filename, number, line, b, p, "Cannot change height after defining glyphs.");
      return false;
    }
    height = new_height;
  } else
  if (startswith(line, width_directive))
  {
    std::string::const_iterator p(line.begin() + width_directive.length());
    const std::string::const_iterator & e(line.end()), b(p);
    unsigned long new_width;
    if (!get_number_eol(new_width, p, e, filename, line, number))
      return false;
    if (bad_width(new_width))
    {
      error(filename, number, line, b, p, bad_width_message);
      return false;
    }
    if (glyphs.size() && width != new_width)
    {
      error(filename, number, line, b, p, "Cannot change width after defining glyphs.");
      return false;
    }
    width = new_width;
  }
  return true;
}

bool                                      /// \return false on a lexing error
VTFont::get_codepoint(
  uint_fast32_t & codepoint,              ///< output
  std::string::const_iterator & p,        ///< start point to work from, updated on return
  const std::string::const_iterator & e,  ///< end of line, already worked out by the caller
  const char * filename,
  const std::string & line,
  unsigned long number
) {
  const std::string::const_iterator b(p);
  codepoint = 0UL;
  while (e != p && std::isxdigit(*p))
  {
    codepoint = codepoint << 4 | x2d(*p);
    ++p;
  }
  if (b == p)
  {
    error(filename, number, line, b, e != b ? b + 1 : b, "Expecting a code point.");
    return false;
  }
  return true;
}

bool                                      /// \return false on a lexing error
VTFont::get_data_eol(
  Glyph::Rows & rows,                     ///< output
  std::string::const_iterator & p,        ///< start point to work from, updated on return
  const std::string::const_iterator & e,  ///< end of line, already worked out by the caller
  const char * filename,
  const std::string & line,
  unsigned long number
) {
  const std::string::const_iterator b(p);
  rows.clear();
  while (e != p && std::isxdigit(*p))
  {
    uint_fast32_t row(0UL);
    for (unsigned int w(0U); w * 4U < width && e != p && std::isxdigit(*p); ++p, ++w)
      row |= x2d(*p) << (width - w * 4U - 4U);
    rows.push_back(row);
  }
  if (b == p)
  {
    error(filename, number, line, p, e, "Expecting a hex-encoded glyph.");
    return false;
  }
  if (e != p)
  {
    error(filename, number, line, p, e, "Unexpected extra stuff.");
    return false;
  }
  return true;
}

bool
VTFont::matches(
  const Glyph & left,
  const Glyph & right
) const {
  if (left.hash != right.hash) return false;
  // We know that they are the same height.
  for (unsigned h(0U) ; h < height; ++h)
  {
    if (left.rows[h] != right.rows[h])
      return false;
  }
  return true;
}

VTFont::GlyphVector::size_type
VTFont::upsert_glyph(
  const Glyph & glyph
) {
#if 0
  std::pair<GlyphHashIndex::const_iterator, GlyphHashIndex::const_iterator> range(hash_index.equal_range(glyph.hash));
  for (GlyphHashIndex::const_iterator p(range.first), e(range.second); e != p; ++p) {
    const GlyphVector::size_type index(p->second);
    if (matches(glyphs[index], glyph))
      return index;
  }
#endif
  const GlyphVector::const_iterator i(glyphs.insert(glyphs.end(), glyph));
  const GlyphVector::size_type index(i - glyphs.begin());
  hash_index.insert(GlyphHashIndex::value_type(glyph.hash, index));
  return index;
}

bool
VTFont::make_map_entries (
  EntryVector & entries,
  const CharacterMap & map,
  const char * filename
) {
  EntryVector::iterator current(entries.end());
  for (CharacterMap::const_iterator p(map.begin()), e(map.end()); e != p; ++p)
  {
    const uint_fast32_t codepoint(p->first);
    const uint_fast32_t glyph(p->second);
    if (current != entries.end())
    {
      if (current->codepoint + current->count + 1U == codepoint && current->glyph + current->count + 1U == glyph && current->count < 0xFFFF)
      {
        ++current->count;
        continue;
      } else {
        if (current->glyph + current->count + 1U > glyphs.size()) {
          error(filename, "Map entry glyph range error.");
          return false;
        }
        current = entries.end();
      }
    }
    vtfont_map_entry entry{};
    entry.codepoint = codepoint;
    entry.glyph = static_cast<uint16_t>(p->second);
    entry.count = 0U; // Count is 1 less than the actual value.
    entries.push_back(entry);
    current = entries.end() - 1;
  }
  for (EntryVector::iterator p(entries.begin()), e(entries.end()); e != p; ++p)
  {
    p->codepoint = htobe32(p->codepoint);
    p->glyph = htobe16(p->glyph);
    p->count = htobe16(p->count);
  }
  return true;
}

bool                                      /// \return false on a load error
VTFont::load (
  unsigned map,
  std::istream & in,                      ///< input stream, presumed already positioned at BOF
  const char * filename
) {
  std::string line;
  unsigned long n(0UL);
  while (getline(in, line))
  {
    ++n;
    std::string::const_iterator p(line.begin()), e(line.end());
    if (e != p && '#' == *p)
    {
      if (!directive(filename, line, n))
        return false;
      continue;
    }
    uint_fast32_t codepoint;
    if (!get_codepoint(codepoint, p, e, filename, line, n))
      return false;
    if (e == p || ':' != *p)
    {
      error(filename, n, line, p, e == p ? p : p + 1, "Expecting a colon.");
      return false;
    } else
      ++p;
    const std::string::const_iterator b(p);
    Glyph::Rows rows;
    if (!get_data_eol(rows, p, e, filename, line, n))
      return false;
    if (rows.size() == height) {
      Glyph glyph;
      for (Glyph::Rows::const_iterator p(rows.begin()), e(rows.end()); e != p; ++p)
        glyph.add_row(*p, (width + 7U) / 8U);
      maps[map][codepoint] = upsert_glyph(glyph);
    } else
    if (rows.size() == height * 2U) {
      Glyph left, right;
      bool which(false);
      for (Glyph::Rows::const_iterator p(rows.begin()), e(rows.end()); e != p; ++p) {
        if (which)
          right.add_row(*p, (width + 7U) / 8U);
        else
          left.add_row(*p, (width + 7U) / 8U);
        which = !which;
      }
      maps[map][codepoint] = upsert_glyph(left);
      maps[map + 1U][codepoint] = upsert_glyph(right);
    } else
    {
      error(filename, n, line, b, p, "Does not work as either a L-only or a L-R font.");
      return false;
    }
  }
  return true;
}

bool                                      /// \return false on a save error
VTFont::save(
  std::ostream & out,                     ///< output stream, presumed already positioned at BOF
  const char * filename
) {
  if (glyphs.size() > 0xFFFF)
  {
    error(filename, "A vt(4) font file cannot hold that many glyphs.");
    return false;
  }
  typedef std::vector<vtfont_map_entry> MapEntryVector;
  MapEntryVector map_entries[sizeof maps/sizeof *maps];
  for (unsigned i(0U); i < sizeof maps/sizeof *maps; ++i) {
    if (!make_map_entries(map_entries[i], maps[i], filename))
      return false;
  }
  vtfont_header header{};
  memcpy(header.magic, "VFNT0002", sizeof header.magic);
  header.width = width;
  header.height = height;
  header.glyphs = htobe32(glyphs.size());
  for (unsigned i(0U); i < sizeof map_entries/sizeof *map_entries; ++i)
    header.map_lengths[i] = htobe32(map_entries[i].size());
  out.write(reinterpret_cast<const char *>(&header), sizeof header);
  if (!out)
  {
    error(filename, std::strerror(errno));
    return false;
  }
  for (GlyphVector::const_iterator p(glyphs.begin()), e(glyphs.end()); e != p; ++p)
  {
    const Glyph & glyph(*p);
    for (unsigned h(0U) ; h < height; ++h)
    {
      if (width <= 8U)
      {
        const uint8_t row(glyph.rows[h] & 0xFF);
        out.write(reinterpret_cast<const char *>(&row), sizeof row);
      } else
      if (width <= 16U)
      {
        const uint16_t row(htobe16(glyph.rows[h] & 0xFFFF));
        out.write(reinterpret_cast<const char *>(&row), sizeof row);
      } else
      if (width <= 24U)
      {
        const uint16_t row_low(htobe16(glyph.rows[h] & 0xFFFF));
        const uint8_t row_high((glyph.rows[h] >> 24U) & 0xFF);
        out.write(reinterpret_cast<const char *>(&row_high), sizeof row_high);
        out.write(reinterpret_cast<const char *>(&row_low), sizeof row_low);
      } else
      {
        const uint32_t row(htobe32(glyph.rows[h] & 0xFFFFFFFF));
        out.write(reinterpret_cast<const char *>(&row), sizeof row);
      }
      if (!out)
      {
        error(filename, std::strerror(errno));
        return false;
      }
    }
  }
  for (unsigned i(0U); i < sizeof map_entries/sizeof *map_entries; ++i)
  {
    out.write(reinterpret_cast<const char *>(map_entries[i].data()), map_entries[i].size() * sizeof(MapEntryVector::value_type));
    if (!out)
    {
      error(filename, std::strerror(errno));
      return false;
    }
  }
  return true;
}

/// \brief main entrypoint
int
main (
  int argc,
  char * argv[]
) {
  const char * prog(basename(argv[0]));
  VTFont font(prog, 8U, 16U);
  int optc;
  while ((optc = getopt_long(argc, argv, short_options, long_options, nullptr)) != -1)
  {
    switch (optc)
    {
      case 'w':
      {
        const char * arg(optarg);
        font.width = std::strtoul(optarg, const_cast<char **>(&arg), 0);
        if (*arg || arg == optarg)
        {
          usage(std::cerr, prog);
          return EXIT_FAILURE;
        }
        break;
      }
      case 'h':
      {
        const char * arg(optarg);
        font.height = std::strtoul(optarg, const_cast<char **>(&arg), 0);
        if (*arg || arg == optarg)
        {
          usage(std::cerr, prog);
          return EXIT_FAILURE;
        }
        break;
      }
      case VERSION_OPTION:
        std::cout << prog << " version " << version << '\n';
        return EXIT_SUCCESS;
      case HELP_OPTION:
        usage(std::cout, prog);
        // Z shell completion demands at least one extra SPC character, otherwise it parses the description as an argument.
        std::cout <<
          "\t--help            \tPrint this help.\n"
          "\t--usage           \tPrint just the usage message.\n"
          "\t--version         \tPrint the version of this program.\n"
          "\t--width, -w width \tSpecify the pixel width of the character set (default is 8).\n"
          "\t--height, -h height \tSpecify the pixel height of the character set (default is 16).\n"
          ;
        return EXIT_SUCCESS;
      case USAGE_OPTION:
        usage(std::cout, prog);
        return EXIT_SUCCESS;
      case '?':
      default:
        usage(std::cerr, prog);
        return EXIT_FAILURE;
      }
  }
  // We can have as many input files as the file format allows maps.
  const char * hexfilenames[VTFont::NUM_MAPS / 2] = {};
  for (unsigned i(0U); i < sizeof hexfilenames/sizeof *hexfilenames; ++i)
  {
    if (optind + 1 >= argc)
    {
      // We must have at least 1 input file.
      if (0 == i)
      {
        usage(std::cerr, prog);
        return EXIT_FAILURE;
      }
      break;
    }
    hexfilenames[i] = argv[optind++];
  }
  // The final argument is the output filename.
  if (optind >= argc)
  {
    usage(std::cerr, prog);
    return EXIT_FAILURE;
  }
  const char * vtfilename(argv[optind++]);
  // Check for spurious trailing arguments.
  if (optind < argc)
  {
    usage(std::cerr, prog);
    return EXIT_FAILURE;
  }

  if (font.bad_width(font.width))
  {
    std::cerr << prog << ": error: " << VTFont::bad_width_message << '\n';
    return EXIT_FAILURE;
  }
  if (font.bad_height(font.height))
  {
    std::cerr << prog << ": error: " << VTFont::bad_height_message << '\n';
    return EXIT_FAILURE;
  }
  for (unsigned i(0U); i < sizeof hexfilenames/sizeof *hexfilenames; ++i)
  {
    const char * hexfilename(hexfilenames[i]);
    if (hexfilename)
    {
      std::ifstream in(hexfilename);
      if (!in)
      {
        const int error(errno);
        std::cerr << prog << ": error: " << hexfilename << ": " << std::strerror(error) << '\n';
        return EXIT_FAILURE;
      }
      if (!font.load(i * 2U, in, hexfilename))
        return EXIT_FAILURE;
    }
  }
  std::ofstream out(vtfilename, std::ios::trunc);
  if (!out)
  {
    const int error(errno);
    std::cerr << prog << ": error: " << vtfilename << ": " << std::strerror(error) << '\n';
    return EXIT_FAILURE;
  }
  if (!font.save(out, vtfilename))
    return EXIT_FAILURE;

  return EXIT_SUCCESS;
}
