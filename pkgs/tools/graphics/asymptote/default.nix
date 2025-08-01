{
  lib,
  stdenv,
  fetchurl,
  autoreconfHook,
  bison,
  glm,
  flex,
  wrapQtAppsHook,
  cmake,
  pkg-config,
  libglut,
  ghostscriptX,
  imagemagick,
  fftw,
  eigen,
  libtirpc,
  boehmgc,
  libGLU,
  libGL,
  libglvnd,
  ncurses,
  readline,
  gsl,
  libsigsegv,
  python3,
  qtbase,
  qtsvg,
  boost186,
  zlib,
  perl,
  curl,
  texinfo,
  texliveSmall,
}:

stdenv.mkDerivation (finalAttrs: {
  version = "3.05";
  pname = "asymptote";

  outputs = [
    "out"
    "man"
    "info"
    "doc"
    "tex"
  ];

  src = fetchurl {
    url = "mirror://sourceforge/asymptote/${finalAttrs.version}/asymptote-${finalAttrs.version}.src.tgz";
    hash = "sha256-NcFtCjvdhppW5O//Rjj4HDqIsva2ZNGWRxAV2/TGmoc=";
  };

  # override with TeX Live containers to avoid building sty, docs from source
  texContainer = null;
  texdocContainer = null;

  nativeBuildInputs = [
    autoreconfHook
    bison
    flex
    bison
    texinfo
    wrapQtAppsHook
    cmake
    ghostscriptX
    perl
    pkg-config
    (python3.withPackages (
      ps: with ps; [
        click
        cson
        numpy
        pyqt5
      ]
    ))
  ]
  ++ lib.optional (finalAttrs.texContainer == null || finalAttrs.texdocContainer == null) (
    texliveSmall.withPackages (
      ps: with ps; [
        epsf
        cm-super
        ps.texinfo
        media9
        ocgx2
        collection-latexextra
      ]
    )
  );

  buildInputs = [
    ghostscriptX
    imagemagick
    fftw
    eigen
    boehmgc
    ncurses
    readline
    gsl
    libsigsegv
    zlib
    perl
    curl
    qtbase
    qtsvg
    # relies on removed asio::io_service
    # https://github.com/kuafuwang/LspCpp/issues/52
    boost186
    (python3.withPackages (
      ps: with ps; [
        cson
        numpy
        pyqt5
      ]
    ))
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [ libtirpc ];

  propagatedBuildInputs = [
    glm
  ]
  ++ lib.optionals stdenv.hostPlatform.isLinux [
    libglut
    libGLU
    libGL
    libglvnd
  ];

  dontWrapQtApps = true;

  # do not build $tex/ls-R which will be generated by texlive.withPackages
  # do not build and install sty and docs, if provided by tex/texdoc texlive containers
  # (this is an optimisation to make texliveMedium and texliveFull independent of texliveSmall)
  preConfigure = ''
    HOME=$TMP
    substituteInPlace Makefile.in \
      --replace-fail ' install-texhash' '''
    if [[ -n $texContainer ]] ; then
      sed -i Makefile.in -e '/(\(latex\|context\)dir)/d'
      substituteInPlace Makefile.in \
        --replace-fail 'asy sty' 'asy'
    else
      prependToVar configureFlags "--with-latex=$tex/tex/latex" "--with-context=$tex/tex/context/third"
    fi
    if [[ -n $texdocContainer ]] ; then
      substituteInPlace Makefile.in \
        --replace-fail ' install-man' ''' \
        --replace-fail 'docdir = $(DESTDIR)@docdir@' 'docdir = $(TMP)/doc'
    fi
  '';

  # do not use bundled libgc.so
  configureFlags = [ "--enable-gc=system" ];

  env.NIX_CFLAGS_COMPILE = "-I${boehmgc.dev}/include/gc";

  postInstall = ''
    rm "$out"/bin/xasy
    chmod +x "$out"/share/asymptote/GUI/xasy.py
    makeQtWrapper "$out"/share/asymptote/GUI/xasy.py "$out"/bin/xasy --prefix PATH : "$out"/bin

    if [[ -z $texdocContainer ]] ; then
      mv "$info"/share/info/asymptote/*.info "$info"/share/info/
      sed -i -e 's|(asymptote/asymptote)|(asymptote)|' "$info"/share/info/asymptote.info
      rmdir "$info"/share/info/asymptote
      rm -f "$info"/share/info/dir
    fi
    install -Dt $out/share/emacs/site-lisp/${finalAttrs.pname} $out/share/asymptote/*.el
  '';

  # fixupPhase crashes if the outputs are not directories
  preFixup = ''
    if [[ -n $texContainer ]] ; then
      mkdir -p "$tex"
    fi
    if [[ -n $texdocContainer ]] ; then
      mkdir -p "$doc" "$man" "$info"
    fi
  '';

  postFixup = ''
    if [[ -n $texContainer ]] ; then
      rmdir "$tex"
      ln -s "$texContainer" "$tex"
    fi
    if [[ -n $texdocContainer ]] ; then
      mkdir -p "$man/share" "$info/share"
      ln -s "$texdocContainer" "$doc/share"
      ln -s "$texdocContainer/doc/man" "$man/share"
      ln -s "$texdocContainer/doc/info" "$info/share"
    fi
  '';

  dontUseCmakeConfigure = true;

  enableParallelBuilding = true;
  # Missing install depends:
  #   ...-coreutils-9.1/bin/install: cannot stat 'asy-keywords.el': No such file or directory
  #   make: *** [Makefile:272: install-asy] Error 1
  enableParallelInstalling = false;

  meta = with lib; {
    description = "Tool for programming graphics intended to replace Metapost";
    homepage = "https://asymptote.sourceforge.io/";
    license = licenses.gpl3Plus;
    maintainers = [ maintainers.raskin ];
    platforms = platforms.linux ++ platforms.darwin;
  };
})
