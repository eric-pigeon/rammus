require 'openssl'

class SslCert
  def self.generate
    key = OpenSSL::PKey::RSA.new(4096)
    public_key = key.public_key

    subject = "CN=rammus-tests"

    cert = OpenSSL::X509::Certificate.new
    cert.subject = cert.issuer = OpenSSL::X509::Name.parse(subject)
    cert.not_before = Time.now
    cert.not_after = Time.now + 365 * 24 * 60 * 60
    cert.public_key = public_key
    cert.serial = generate_serial
    cert.version = 2

    ef = OpenSSL::X509::ExtensionFactory.new
    ef.subject_certificate = cert
    ef.issuer_certificate = cert
    cert.add_extension ef.create_extension("basicConstraints","CA:TRUE", true)
    cert.add_extension ef.create_extension("subjectKeyIdentifier", "hash")
    cert.add_extension ef.create_extension("authorityKeyIdentifier", "keyid:always,issuer:always")
    cert.add_extension ef.create_extension("authorityKeyIdentifier", "keyid:always,issuer:always")

    cert.sign key, OpenSSL::Digest::SHA256.new

    [cert.to_pem, key.to_s]
  end

  def self.generate_serial
    (Time.now.to_f * 10**12).to_i + Random.rand(10000)
  end
end

