# letsencrypt_wildcard

This is a simple module for handling Amazon Route 53 DNS-based wildcard
certificates with Puppet. It uses
[puppet-letsencrypt](https://github.com/voxpupuli/puppet-letsencrypt) for the
hard lifting.

It can be used in conjunction with the Puppet fileserver to automatically have
nodes update their certificates when they have changed.

# Prerequisites

This module will not work unless you've set up an IAM user and granted it
permission to modify DNS records for the zone(s) you wish to get certificates
for. You will also need AWS API keys for that user. The official sample IAM
policy for certbot-route53 is
[here](https://github.com/certbot/certbot/blob/master/certbot-dns-route53/examples/sample-aws-policy.json).

# Usage

Using this module is fairly straightforward:

```
class { 'letsencrypt_wildcard':
  email                 => 'admin@example.org',
  aws_access_key_id     => 'my-access-key-id',
  aws_secret_access_key => 'my-secret-access-key',
  internal_dns_domains  => ['beta.example.in', 'production.example.in'],
  external_dns_domains  => ['beta.example.net', 'production.example.net'],
}
```

To copy the renewed certificates to a directory (e.g. Puppet fileserver share) use the
\$certs_copy_dir parameter.
