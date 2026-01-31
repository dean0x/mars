class Mars < Formula
  desc "Multi-repo workspace manager for Git repositories"
  homepage "https://github.com/dean0x/mars"
  url "https://github.com/dean0x/mars/archive/refs/tags/v0.1.0.tar.gz"
  sha256 "PLACEHOLDER_SHA256"
  license "MIT"

  def install
    bin.install "dist/mars" => "mars"
  end

  test do
    system "#{bin}/mars", "--version"
  end
end
