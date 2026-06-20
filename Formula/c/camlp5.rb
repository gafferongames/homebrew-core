class Camlp5 < Formula
  desc "Preprocessor and pretty-printer for OCaml"
  homepage "https://camlp5.github.io/"
  url "https://github.com/camlp5/camlp5/archive/refs/tags/8.05.02.tar.gz"
  sha256 "ceceb2377563f5483738090b614447536daa4cea119dc768a0659543727b4497"
  license "BSD-3-Clause"
  revision 1
  head "https://github.com/camlp5/camlp5.git", branch: "master"

  livecheck do
    url "https://opam.ocaml.org/packages/camlp5/"
    regex(%r{href=.*?/refs/tags/(?:rel[._-]?)?v?(\d+(?:\.\d+)+)\.t}i)
  end

  bottle do
    sha256 arm64_tahoe:   "5afe5ae61c0f6733ce060368645d0a8e3155f408a7fc969c4ff43a6e836ae663"
    sha256 arm64_sequoia: "6c35e0cd579615f42af75e470aedb8be26926c2b447d8b4a38046d6719e0607f"
    sha256 arm64_sonoma:  "b080617a738ecd08fcaf0022cad58a73ba6bc625b897253e0aa075a72417bd20"
    sha256 sonoma:        "9a3a1d605b10ce0c19b2fa3ae2be7c6ec7e595df5d33853e4ec12a62a36ef066"
    sha256 arm64_linux:   "488071c24fce094fa32c5f272f4329024dc70947af8bfdf5c20d815de069cf76"
    sha256 x86_64_linux:  "f557a2ee43d702574d642489d575f7edfdf83f2f5bc30f5cdfbfc18bb209fa75"
  end

  depends_on "ocaml-findlib" => :build
  depends_on "opam" => :build
  depends_on "pkgconf" => :build
  depends_on "camlp-streams"
  depends_on "ocaml"
  depends_on "pcre2"

  uses_from_macos "m4" => :build

  def install
    ENV["OPAMROOT"] = opamroot = buildpath/".opam"
    ENV["OPAMYES"] = "1"

    system "opam", "init", "--compiler=ocaml-system", "--disable-sandboxing", "--no-setup"
    system "opam", "install", ".", "--deps-only", "--yes", "--no-depexts"

    # OCaml 5.5.0 dropped `CAML_LD_LIBRARY_PATH` from the `ocaml` opam package's
    # `setenv`, so with an `ocaml-system` switch the bytecode linker can no longer
    # find opam-installed C stubs (e.g. dllpcre2_stubs.so) at link time.
    # https://github.com/ocaml/opam-repository/issues/16406
    ENV.prepend_path "CAML_LD_LIBRARY_PATH", opamroot/"ocaml-system/lib/stublibs"

    system "./configure", "--prefix", prefix, "--libdir", lib/"ocaml", "--mandir", man
    system "opam", "exec", "--", "make", "world.opt"
    system "opam", "exec", "--", "make", "install"
    (lib/"ocaml/camlp5").install "etc/META"
    libexec.install opamroot/"ocaml-system/lib/stublibs/dllpcre2_stubs.so"
    bin.env_script_all_files libexec, CAML_LD_LIBRARY_PATH: libexec
  end

  test do
    ocaml = Formula["ocaml"]
    (testpath/"hi.ml").write "print_endline \"Hi!\";;"
    assert_equal "let _ = print_endline \"Hi!\"",
      # The purpose of linking with the file "str.cma" is to ensure that the
      # ocaml files are in sync with the camlp5 files.  If camlp5 has been
      # compiled with an older version of the ocaml compiler, then an error
      # "interface mismatch" will occur.
      shell_output("#{bin}/camlp5 #{lib}/ocaml/camlp5/pa_o.cmo " \
                   "#{lib}/ocaml/camlp5/o_keywords.cmo " \
                   "#{lib}/ocaml/camlp5/pr_o.cmo " \
                   "#{ocaml.opt_lib}/ocaml/str/str.cma hi.ml")
  end
end
