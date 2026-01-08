package com.directsmtp;

import java.io.File;
import java.io.FileInputStream;
import java.security.KeyStore;
import java.security.cert.CertificateFactory;
import java.security.cert.X509Certificate;

public class TrustBundleLoader {

    public static KeyStore loadTrustBundle(String folderPath) throws Exception {
        File folder = new File(folderPath);
        KeyStore ks = KeyStore.getInstance(KeyStore.getDefaultType());
        ks.load(null, null);

        CertificateFactory cf = CertificateFactory.getInstance("X.509");

        int i = 0;
        for(File f : folder.listFiles()) {
            if(f.getName().endsWith(".crt")) {
                X509Certificate cert = (X509Certificate) cf.generateCertificate(new FileInputStream(f));
                ks.setCertificateEntry("cert" + i, cert);
                i++;
            }
        }
        return ks;
    }
}
