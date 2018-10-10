class Vim < Formula
  desc "Vim without Perl, without NLS, no GUI, and Python 3, with no option of Python 2"
  homepage "https://www.vim.org/"
  # vim should only be updated every 50 releases on multiples of 50
  url "https://bintray.com/homebrew/bottles/download_file?file_path=vim-8.1.0450.high_sierra.bottle.tar.gz"
	sha256 "3b29264c595e606925615fcc9d352f38be1021ca2d11c6a97b933d1981853b0f"
  head "https://github.com/vim/vim.git"

  bottle do
    sha256 "3e89d338989d4c96f679c3f6afe35e389d28d6f344199c526c66cb69c6abff2a" => :mojave
    sha256 "3b29264c595e606925615fcc9d352f38be1021ca2d11c6a97b933d1981853b0f" => :high_sierra
    sha256 "b839af7e8dadc53f31cbb06539ca169c494602da297329e0755832811d8435ed" => :sierra
  end

  option "with-override-system-vi", "Override system vi"
  deprecated_option "override-system-vi" => "with-override-system-vi"

  LANGUAGES_OPTIONAL = %w[python lua tcl].freeze

  LANGUAGES_OPTIONAL.each do |language|
    option "with-#{language}", "Build vim with #{language} support"
  end

  depends_on "ruby" => :optional
  depends_on "lua" => :optional
  depends_on "luajit" => :optional

  conflicts_with "ex-vi",
    :because => "vim and ex-vi both install bin/ex and bin/view"

  def install
    #ENV.prepend_path "PATH", Formula["python"].opt_libexec/"bin"
    ENV.prepend_path "PATH", "/Users/chb/Users/chb/.pyenv/versions/threesevenzero/bin/python"

    # https://github.com/Homebrew/homebrew-core/pull/1046
    ENV.delete("SDKROOT")

    # vim doesn't require any Python package, unset PYTHONPATH.
    ENV.delete("PYTHONPATH")

    opts = [ "--with-features=huge", "--enable-darwin", "--enable-gui=no",
            "--without-x", "--enable-luainterp=yes", "--enable-python3interp=yes", 
            "--enable-tclinterp=yes", "--enable-rubyinterp=yes", "--enable-perlinterp=no",
            "--enable-largefile", "--enable-acl", "--with-mac-arch=intel", 
            "--with-developer-dir=/Library/Developer" ]            

    opts << "--disable-nls"
    opts << "--enable-gui=no"
    opts << "--without-x"

    if build.with?("lua") || build.with?("luajit")
      opts << "--enable-luainterp"

    if build.with? "luajit"
        opts << "--with-luajit"
        opts << "--with-lua-prefix=#{Formula["luajit"].opt_prefix}"
      else
        opts << "--with-lua-prefix=#{Formula["lua"].opt_prefix}"
    end

      if build.with?("lua") && build.with?("luajit")
        onoe <<~EOS
          Vim will not link against both Luajit & Lua simultaneously.
          Proceeding with Lua.
        EOS
        opts -= %w[--with-luajit]
      end
    end

    # We specify HOMEBREW_PREFIX as the prefix to make vim look in the
    # the right place (HOMEBREW_PREFIX/share/vim/{vimrc,vimfiles}) for
    # system vimscript files. We specify the normal installation prefix
    # when calling "make install".
    # Homebrew will use the first suitable Perl & Ruby in your PATH if you
    # build from source. Please don't attempt to hardcode either.
    system "./configure", "--prefix=#{HOMEBREW_PREFIX}",
                          "--mandir=#{man}",
                          "--enable-multibyte",
                          "--with-tlib=ncurses",
                          "--enable-cscope",
                          "--enable-terminal",
                          "--with-compiledby=Homebrew",
                          *opts
    system "make"
    # Parallel install could miss some symlinks
    # https://github.com/vim/vim/issues/1031
    ENV.deparallelize
    # If stripping the binaries is enabled, vim will segfault with
    # statically-linked interpreters like ruby
    # https://github.com/vim/vim/issues/114
    system "make", "install", "prefix=#{prefix}", "STRIP=#{which "true"}"
    bin.install_symlink "vim" => "vi" if build.with? "override-system-vi"
  end

  test do
    if build.with? "python"
      (testpath/"commands.vim").write <<~EOS
        :python3 import vim; vim.current.buffer[0] = 'hello python3'
        :wq
      EOS
      system bin/"vim", "-T", "dumb", "-s", "commands.vim", "test.txt"
      assert_equal "hello python3", File.read("test.txt").chomp
    end
  end
end
