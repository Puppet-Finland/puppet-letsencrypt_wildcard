#
# @summary
#   Renew letsencrypt wildcard certificates with Amazon Route 53 plugin
#
# @param email
#   Email address to use with Letsencrypt
# @param aws_access_key_id
#   AWS access key ID to use with certbot
# @param aws_secret_access_key
#   AWS secret access key to use with certbot
# @param cron_scripts_path
#   Where to place the certbot renewal scripts launched from cron. This is
#   mainly for Puppet Bolt compatibility, where the default from
#   puppet-letsencrypt (puppet vardir fact) breaks horribly.
# @param internal_dns_domains
#   Internal DNS domains for which to create wildcard certificates
# @param external_dns_domains
#   External DNS domains for which to create wildcard certificates
# @param certs_copy_dir
#   Directory to copy the certificates to. This can, for example, be a Puppet
#   fileserver directory.
#
class letsencrypt_wildcard (
  String               $email,
  String               $aws_access_key_id,
  String               $aws_secret_access_key,
  Stdlib::Absolutepath $cron_scripts_path = '/var/lib/letsencrypt',
  Array[String]        $internal_dns_domains = [],
  Array[String]        $external_dns_domains = [],
  Optional[String]     $certs_copy_dir = undef,
) {
  file { '/root/.aws':
    ensure => 'directory',
    owner  => 'root',
    group  => 'root',
    mode   => '0700',
  }

  file { '/root/.aws/config':
    ensure  => 'file',
    content => template('letsencrypt_wildcard/letencrypt_wildcard_aws_config.erb'),
    owner   => 'root',
    group   => 'root',
    mode    => '0600',
    require => File['/root/.aws'],
  }

  class { 'letsencrypt':
    email             => $email,
    cron_scripts_path => $cron_scripts_path,
    configure_epel    => false,
  }

  $all_dns_domains = $internal_dns_domains + $external_dns_domains

  $all_dns_domains.each |$dns_domain| {
    letsencrypt::certonly { $dns_domain:
      domains              => ["*.${dns_domain}"],
      plugin               => 'dns-route53',
      manage_cron          => true,
      suppress_cron_output => true,
      require              => [
        Class['letsencrypt'],
      ],
    }

    # Optionally copy the certs to a directory for further distribution. The
    # directory is typically the Puppet fileserver's global directory.
    if $certs_copy_dir {
      $cert_defaults = { 'ensure'  => 'present',
        'links'   => 'follow',
        'owner'   => 'puppet',
        'group'   => 'puppet',
        'mode'    => '0440',
      'require' => Letsencrypt::Certonly[$dns_domain], }

      file { "${certs_copy_dir}/sslcert-${dns_domain}.crt":
        source => "/etc/letsencrypt/live/${dns_domain}/cert.pem",
        *      => $cert_defaults,
      }

      file { "${certs_copy_dir}/sslcert-${dns_domain}.key":
        source => "/etc/letsencrypt/live/${dns_domain}/privkey.pem",
        *      => $cert_defaults,
      }

      file { "${certs_copy_dir}/sslcert-${dns_domain}-fullchain.crt":
        source => "/etc/letsencrypt/live/${dns_domain}/fullchain.pem",
        *      => $cert_defaults,
      }
    }
  }
}
