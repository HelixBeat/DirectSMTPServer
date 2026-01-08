package com.directsmtp;

import org.bouncycastle.cms.CMSSignedData;
import org.bouncycastle.cms.CMSException;
import java.io.InputStream;

public class SMIMEUtils {
    public static boolean verifySMIME(InputStream emailData) throws Exception {
        try {
            byte[] data = emailData.readAllBytes();
            CMSSignedData signedData = new CMSSignedData(data);
            return signedData.getSignerInfos().size() > 0;
        } catch (CMSException e) {
            e.printStackTrace();
            return false;
        }
    }
}