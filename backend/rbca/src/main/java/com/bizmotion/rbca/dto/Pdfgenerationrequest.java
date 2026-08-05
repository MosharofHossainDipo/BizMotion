package com.bizmotion.rbca.dto;

import lombok.Getter;
import lombok.Setter;

@Getter @Setter
public class Pdfgenerationrequest {
    private boolean letterhead = false;
    /** Optional data-URL or raw base64 of an uploaded signature image,
     *  overlaid on the "Authorized Signature and Seal" line. */
    private String signatureImageBase64;
}