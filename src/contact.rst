Please use my email id on the homepage of this website to contact me. Follow the
netiquette guidelines mentioned in `rfc 1855
<https://tools.ietf.org/html/rfc1855>`_. Use only plain text emails. If
formatting is essential, then attach the formatted content as a pdf. Please wait
at least three days for a reply before sending me a reminder. If you need to
contact me urgently, use my phone number.

I am not on any social networks.

If you wish to send me a private email, remember that unencrypted emails are
more like postcards than sealed envelopes. The only way to ensure that emails
you send to me can only be read by me is to encrypt them using my `key
<data/bkomarath_public_key.txt>`_. You should also verify the fingerprint for my
key with me through a separate, secure channel (in person or through phone)
before using the key. The FSF has written an excellent `guide
<https://emailselfdefense.fsf.org/en/>`_ on secure communication over email. The
exact steps to send secure emails depend on the email client.

You can send encrypted messages with minimal setup as follows::

    $ gpg --import bkomarath_public_key.txt
    $ gpg --encrypt --armor -r bkomarath@rbgo.in message

This assumes that you have installed GnuPG on your system. First, import my
public key given above. Assuming that you have typed in the message for me into
a file called ``message``, use the encrypt option to encrypt it for my eyes
only. The output will be written to a file named ``message.asc``. Now, you can
send this ``message.asc`` file to me.
