package com.bizmotion.rbca.service;

import com.bizmotion.rbca.dto.InvoiceDto;
import com.bizmotion.rbca.dto.InvoiceItemDto;
import com.itextpdf.io.image.ImageDataFactory;
import com.itextpdf.kernel.colors.DeviceRgb;
import com.itextpdf.kernel.events.Event;
import com.itextpdf.kernel.events.IEventHandler;
import com.itextpdf.kernel.events.PdfDocumentEvent;
import com.itextpdf.kernel.geom.PageSize;
import com.itextpdf.kernel.geom.Rectangle;
import com.itextpdf.kernel.pdf.PdfDocument;
import com.itextpdf.kernel.pdf.PdfPage;
import com.itextpdf.kernel.pdf.PdfWriter;
import com.itextpdf.kernel.pdf.canvas.PdfCanvas;
import com.itextpdf.kernel.pdf.canvas.draw.SolidLine;
import com.itextpdf.layout.Canvas;
import com.itextpdf.layout.Document;
import com.itextpdf.layout.borders.Border;
import com.itextpdf.layout.borders.SolidBorder;
import com.itextpdf.layout.element.*;
import com.itextpdf.layout.layout.LayoutArea;
import com.itextpdf.layout.properties.AreaBreakType;
import com.itextpdf.layout.properties.HorizontalAlignment;
import com.itextpdf.layout.properties.TextAlignment;
import com.itextpdf.layout.properties.UnitValue;
import com.itextpdf.layout.properties.VerticalAlignment;
import org.springframework.core.io.ClassPathResource;
import org.springframework.stereotype.Service;

import java.io.ByteArrayOutputStream;
import java.io.IOException;
import java.math.BigDecimal;
import java.time.format.DateTimeFormatter;
import java.util.Base64;
import java.util.Locale;

@Service
public class Invoicepdfservice {

    private static final DeviceRgb BORDER_COLOR = new DeviceRgb(191, 191, 191);
    private static final DeviceRgb HEADER_BG    = new DeviceRgb(243, 243, 243);
    private static final DateTimeFormatter DATE_FMT = DateTimeFormatter.ofPattern("dd/MM/yyyy");

    /** Place D:\rbca\rbca\src\main\resources\static\logo.png (create the
     *  "static" folder if it doesn't exist) -- that's where this loads the
     *  company logo from. If the file isn't there, the PDF still generates
     *  fine, just without the logo image. */
    private static final String LOGO_CLASSPATH = "static/logo.png";

    public byte[] generate(InvoiceDto inv, boolean letterhead, String signatureImageBase64) throws IOException {
        ByteArrayOutputStream baos = new ByteArrayOutputStream();
        PdfWriter writer = new PdfWriter(baos);
        PdfDocument pdfDoc = new PdfDocument(writer);
        pdfDoc.setDefaultPageSize(PageSize.A4);

        byte[] logoBytes = loadLogoBytes();

        pdfDoc.addEventHandler(PdfDocumentEvent.END_PAGE, new HeaderFooterHandler(letterhead, logoBytes));

        Document doc = new Document(pdfDoc, PageSize.A4);
        // Same top margin whether letterhead mode or not — in letterhead
        // mode we simply don't draw our OWN header/logo into that space,
        // but the space itself must stay reserved/blank so invoice content
        // never overlaps the pre-printed company letterhead artwork at the
        // top of the physical paper.
        doc.setMargins(110, 40, 70, 40);

        if (!letterhead) {
            doc.add(new Paragraph("Tracking No: " + orDash(inv.getTrackingNumber()))
                    .setTextAlignment(TextAlignment.CENTER).setFontSize(9));
        }

        if (inv.getSubject() != null && !inv.getSubject().isBlank()) {
            doc.add(new Paragraph(inv.getSubject()).setBold().setFontSize(13).setMarginBottom(12));
        }

        Table topGrid = new Table(UnitValue.createPercentArray(new float[]{58, 42})).useAllAvailableWidth();
        Cell billCell = new Cell().setBorder(Border.NO_BORDER);
        billCell.add(new Paragraph("Invoiced To").setBold().setFontSize(9));
        billCell.add(new Paragraph(inv.getCustomerName()).setBold().setFontSize(9));
        if (inv.getBillingAddress() != null && !inv.getBillingAddress().isBlank()) {
            billCell.add(new Paragraph(inv.getBillingAddress()).setFontSize(9));
        }
        topGrid.addCell(billCell);
        topGrid.addCell(new Cell().setBorder(Border.NO_BORDER).add(buildInfoTable(inv)));
        topGrid.setMarginBottom(24);
        doc.add(topGrid);

        Table items = new Table(UnitValue.createPercentArray(new float[]{58, 14, 10, 18})).useAllAvailableWidth();
        addHeaderCell(items, "Item");
        addHeaderCell(items, "Price");
        addHeaderCell(items, "Qty");
        addHeaderCell(items, "Total");
        for (InvoiceItemDto item : inv.getItems()) {
            items.addCell(dataCell(item.getDescription() == null ? "Line item" : item.getDescription(), TextAlignment.LEFT));
            items.addCell(dataCell(money(inv, item.getUnitPrice()), TextAlignment.RIGHT));
            items.addCell(dataCell(item.getQty().setScale(2, java.math.RoundingMode.HALF_UP).toString(), TextAlignment.CENTER));
            items.addCell(dataCell(money(inv, item.getLineTotal()), TextAlignment.RIGHT));
        }
        doc.add(items);

        Table totals = new Table(UnitValue.createPercentArray(new float[]{58, 14, 10, 18})).useAllAvailableWidth();
        if (inv.getTaxPercent() != null && inv.getTaxPercent().compareTo(BigDecimal.ZERO) > 0) {
            totals.addCell(dataCell("Tax (" + inv.getTaxPercent() + "%)", TextAlignment.LEFT));
            totals.addCell(dataCell(money(inv, inv.getTaxTotal()), TextAlignment.RIGHT));
            totals.addCell(dataCell("1.00", TextAlignment.CENTER));
            totals.addCell(dataCell(money(inv, inv.getTaxTotal()), TextAlignment.RIGHT).setBold());
        }
        totals.addCell(summaryLabelCell("Sub Total", 9));
        totals.addCell(summaryValueCell(money(inv, inv.getSubtotal()), 9));
        totals.addCell(summaryLabelCell("Grand Total", 11));
        totals.addCell(summaryValueCell(money(inv, inv.getGrandTotal()), 11));
        totals.setKeepTogether(true);
        doc.add(totals);

       float neededHeight = 150;
            LayoutArea currentArea = doc.getRenderer().getCurrentArea();
            float remainingHeight = currentArea != null ? currentArea.getBBox().getHeight() : 0;
            if (remainingHeight < neededHeight) {
            doc.add(new AreaBreak(AreaBreakType.NEXT_PAGE));
         }

        Div bottom = new Div().setKeepTogether(true);

        bottom.add(new Paragraph("Payment to: Current A/C Number: 1507 2033 1680 7001; " +
        "(Account Name: BIZ MOTION LIMITED) BRAC Bank Limited")
        .setBold().setFontSize(9).setMarginTop(14).setMarginBottom(80));

        // 45% / 10% (blank spacer) / 45% — the middle spacer column is the
        // fix for the two signature lines looking like they're touching:
        // before, the two lines sat in adjacent 50/50 cells with no gap
        // between them at all.
        Table sigRow = new Table(UnitValue.createPercentArray(new float[]{45, 10, 45})).useAllAvailableWidth();

        Cell authCell = new Cell().setBorder(Border.NO_BORDER)
                .setTextAlignment(TextAlignment.CENTER)
                .setVerticalAlignment(VerticalAlignment.BOTTOM);
       if (signatureImageBase64 != null && !signatureImageBase64.isBlank()) {
       try {
        byte[] imgBytes = Base64.getDecoder().decode(stripDataUrlPrefix(signatureImageBase64));
        System.out.println("Signature bytes length: " + imgBytes.length);
        Image sigImg = new Image(ImageDataFactory.create(imgBytes));
        sigImg.setAutoScale(false);
        sigImg.scaleToFit(100, 35);
        sigImg.setHorizontalAlignment(HorizontalAlignment.CENTER);
        authCell.add(sigImg);
    } catch (Exception e) {
        e.printStackTrace(); 
    }
    } else {
        System.out.println("signatureImageBase64 is null/blank");
    }
        
        authCell.add(new LineSeparator(new SolidLine(1)).setMarginBottom(3));
        authCell.add(new Paragraph("Authorized Signature and Seal").setBold().setFontSize(8));
        sigRow.addCell(authCell);

        sigRow.addCell(new Cell().setBorder(Border.NO_BORDER)); 

        Cell clientCell = new Cell().setBorder(Border.NO_BORDER)
                .setTextAlignment(TextAlignment.CENTER)
                .setVerticalAlignment(VerticalAlignment.BOTTOM);
        clientCell.add(new LineSeparator(new SolidLine(1)).setMarginBottom(3));
        clientCell.add(new Paragraph("Client Signature and Seal").setBold().setFontSize(8));
        sigRow.addCell(clientCell);

        bottom.add(sigRow);
        doc.add(bottom);

        doc.close();
        return baos.toByteArray();
    }

    private byte[] loadLogoBytes() {
        try {
            ClassPathResource resource = new ClassPathResource(LOGO_CLASSPATH);
            if (!resource.exists()) return null;
            return resource.getInputStream().readAllBytes();
        } catch (Exception e) {
            return null;
        }
    }

    private Table buildInfoTable(InvoiceDto inv) {
        Table t = new Table(UnitValue.createPercentArray(new float[]{40, 60})).useAllAvailableWidth();
        addInfoRow(t, "Invoice", inv.getInvoiceNumber());
        addInfoRow(t, "Status", inv.getStatus());
        addInfoRow(t, "Invoice Date", inv.getInvoiceDate() == null ? "-" : inv.getInvoiceDate().format(DATE_FMT));
        addInfoRow(t, "Due Date", inv.getDueDate() == null ? "-" : inv.getDueDate().format(DATE_FMT));
        addInfoRow(t, "Amount Due", money(inv, inv.getGrandTotal()));
        return t;
    }

    private void addInfoRow(Table t, String label, String value) {
        t.addCell(new Cell().setBorder(new SolidBorder(BORDER_COLOR, 0.5f)).setBackgroundColor(HEADER_BG)
                .add(new Paragraph(label).setBold().setFontSize(9)));
        t.addCell(new Cell().setBorder(new SolidBorder(BORDER_COLOR, 0.5f))
                .add(new Paragraph(value).setFontSize(9).setTextAlignment(TextAlignment.RIGHT)));
    }

    private void addHeaderCell(Table t, String text) {
        t.addHeaderCell(new Cell().setBorder(new SolidBorder(BORDER_COLOR, 0.5f)).setBackgroundColor(HEADER_BG)
                .add(new Paragraph(text).setBold().setFontSize(9).setTextAlignment(TextAlignment.CENTER)));
    }

    private Cell dataCell(String text, TextAlignment align) {
        return new Cell().setBorder(new SolidBorder(BORDER_COLOR, 0.5f))
                .add(new Paragraph(text).setFontSize(9).setTextAlignment(align));
    }

    private Cell summaryLabelCell(String text, int fontSize) {
        return new Cell(1, 3).setBorder(new SolidBorder(BORDER_COLOR, 0.5f)).setBackgroundColor(HEADER_BG)
                .add(new Paragraph(text).setBold().setFontSize(fontSize).setTextAlignment(TextAlignment.RIGHT));
    }

    private Cell summaryValueCell(String text, int fontSize) {
        return new Cell().setBorder(new SolidBorder(BORDER_COLOR, 0.5f))
                .add(new Paragraph(text).setBold().setFontSize(fontSize).setTextAlignment(TextAlignment.RIGHT));
    }

    private String money(InvoiceDto inv, BigDecimal value) {
        String symbol;
        switch (inv.getCurrency() == null ? "" : inv.getCurrency()) {
            case "USD": symbol = "$"; break;
            case "EUR": symbol = "EUR "; break;
            default:    symbol = "Tk "; break;
        }
        return symbol + String.format(Locale.US, "%,.2f", value == null ? BigDecimal.ZERO : value);
    }

    private String orDash(String s) { return (s == null || s.isBlank()) ? "-" : s; }

    private String stripDataUrlPrefix(String base64) {
        int comma = base64.indexOf(',');
        return comma >= 0 ? base64.substring(comma + 1) : base64;
    }

    private static class HeaderFooterHandler implements IEventHandler {
        private final boolean letterhead;
        private final byte[] logoBytes;

        HeaderFooterHandler(boolean letterhead, byte[] logoBytes) {
            this.letterhead = letterhead;
            this.logoBytes = logoBytes;
        }

        @Override
        public void handleEvent(Event event) {
            if (letterhead) return;

            PdfDocumentEvent docEvent = (PdfDocumentEvent) event;
            PdfPage page = docEvent.getPage();
            PdfDocument pdfDoc = docEvent.getDocument();
            int pageNumber = pdfDoc.getPageNumber(page);
            Rectangle pageSize = page.getPageSize();
            PdfCanvas pdfCanvas = new PdfCanvas(page);

            try (Canvas footerCanvas = new Canvas(pdfCanvas, new Rectangle(40, 20, pageSize.getWidth() - 80, 40))) {
                footerCanvas.add(new Paragraph("House no # 995, Road no# 9/A, Avenue 11, Mirpur DOHS, Dhaka-1216.")
                        .setFontSize(8).setTextAlignment(TextAlignment.CENTER));
                footerCanvas.add(new Paragraph("Email: contact@biz-motion.com, web: www.biz-motion.com")
                        .setFontSize(8).setTextAlignment(TextAlignment.CENTER));
            }

            if (pageNumber == 1) {
                if (logoBytes != null) {
                    try {
                        Image logo = new Image(ImageDataFactory.create(logoBytes)).setWidth(50);
                        float logoX = pageSize.getWidth() - 40 - 50;
                        float logoY = pageSize.getHeight() - 75;
                        logo.setFixedPosition(pageNumber, logoX, logoY);
                        try (Canvas logoCanvas = new Canvas(pdfCanvas, pageSize)) {
                            logoCanvas.add(logo);
                        }
                    } catch (Exception ignored) {
                    }
                }
                try (Canvas headerCanvas = new Canvas(pdfCanvas, new Rectangle(40, pageSize.getHeight() - 95, pageSize.getWidth() - 80, 20))) {
                    headerCanvas.add(new Paragraph("BIZMOTION LIMITED.").setBold().setFontSize(9).setTextAlignment(TextAlignment.RIGHT));
                }
                pdfCanvas.saveState()
                        .setLineWidth(2)
                        .moveTo(40, pageSize.getHeight() - 100)
                        .lineTo(pageSize.getWidth() - 40, pageSize.getHeight() - 100)
                        .stroke()
                        .restoreState();
            }
        }
    }
}