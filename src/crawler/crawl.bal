import ballerina/http;
import ballerina/io;
import ballerina/lang. 'xml as xmls;
import ballerina/streams;

public function main(string... args) {
    http:Client nlbClient = new ("https://www.nlb.lk");
    var response = nlbClient->get("/English");
    io:println("Connected");
    string hello = "<!DOCTYPE>";
    if (response is error) {
        io:println("Error connecting to NLB endpoint");
        io:println(response.toString());
    } else {
        io:println("Response Received");
        getPrizesFromHtml(response);
    }
}

function getPrizesFromHtml(http:Response response) {
    string contentType = response.getContentType();
    string docTypeTag = "<!DOCTYPE html>";
    if (!contentType.startsWith("text/html")) {
        io:println("invalid content Type");
    }
    string | error textPayload = response.getTextPayload();
    if (textPayload is error) {
        io:println("Invalid Response");
    } else {
        int htmlStartIndex = 0;
        htmlStartIndex = docTypeTag.length();
        string htmlContent = textPayload.substring(htmlStartIndex, textPayload.length());
        string priceHeader = "<h2>Today Super Prizes</h2>";
        string tableEnd = "</table>";
        int? priceHeaderStart = htmlContent.indexOf(priceHeader);
        int priceTableStart = 0;
        int priceTableEnd = 0;
        if (priceHeaderStart is int) {
            priceTableStart = priceHeaderStart + priceHeader.length();
            int? tableEndIndex = htmlContent.indexOf(tableEnd, priceTableStart);
            if (tableEndIndex is int) {
                priceTableEnd = tableEndIndex + tableEnd.length();
            }
        }

        if (priceTableStart <= 0 || priceTableEnd <= 0) {
            return ();
        }
        string tableContent = htmlContent.substring(priceTableStart, priceTableEnd);
        (xml | error) prizesTable = removeImgTags(tableContent);
        if (prizesTable is xml) {
            printAllPrices(prizesTable);
        }
    }
}

function removeImgTags(string extractedContent) returns xml | error {
    string resultString = extractedContent;
    string imgTagStart = "<img";
    string imgTagEnd = ">";
    boolean proceed = true;

    io:println("======= removeImgTags ========");

    while (proceed) {
        int? imgStart = resultString.indexOf(imgTagStart, 0);

        if (imgStart is int) {
            int? imgEnd = resultString.indexOf(imgTagEnd, imgStart);
            if (imgEnd is int) {
                imgEnd = imgEnd + imgTagEnd.length();
                resultString = resultString.substring(0, imgStart) + resultString.substring(imgEnd, resultString.length());
            } else {
                proceed = false;
            }
        } else {
            proceed = false;
        }
    }
    return xmls:fromString(resultString.trim());
}

function printAllPrices(xml prizesTable) {
    xml rows =prizesTable.*.elements();
    rows.forEach(function ((xml | string) row) {
        if (row is xml) {
            row.*.elements().forEach( function (xml | string element) {
                if (element is xml) {
                    if (element.*.elements().isEmpty()) {
                        io:println(element.getTextValue());
                    }
                }
            });
        }
    });
}
