xquery version "3.1";

module namespace idx="http://teipublisher.com/index";

declare namespace tei="http://www.tei-c.org/ns/1.0";
declare namespace dbk="http://docbook.org/ns/docbook";

declare variable $idx:app-root :=
    let $rawPath := system:get-module-load-path()
    return
        (: strip the xmldb: part :)
        if (starts-with($rawPath, "xmldb:exist://")) then
            if (starts-with($rawPath, "xmldb:exist://embedded-eXist-server")) then
                substring($rawPath, 36)
            else
                substring($rawPath, 15)
        else
            $rawPath
    ;

(:~
 : Helper function called from collection.xconf to create index fields and facets.
 : This module needs to be loaded before collection.xconf starts indexing documents
 : and therefore should reside in the root of the app.
 :)
declare function idx:get-metadata($root as element(), $field as xs:string) {
    let $header := $root/tei:teiHeader
    return
        switch ($field)
            case "title" return
                string-join((
                    $header//tei:msDesc/tei:head, $header//tei:titleStmt/tei:title
                ), " - ")
            case "author" return 
                idx:get-person($header//tei:msDesc//tei:msItem/tei:author)
            case "place" return 
                's.l.'
            case "keyword" return
                $header//tei:profileDesc//tei:keywords//tei:term
            case "notAfter" return
                idx:get-notAfter($header//tei:sourceDesc//tei:history/tei:origin/tei:origDate)
            case "notBefore" return
                idx:get-notBefore($header//tei:sourceDesc//tei:history/tei:origin/tei:origDate)
            case "language" return
                    $root/@xml:lang
            
            case "genre" return (
                idx:get-genre($header),
                'charter'
            )
            default return
                ()
};

declare function idx:get-person($persName as element()*) {
    for $p in $persName
    return
    if ($p/@key and $p/@key != '') then $p/@key/string() else $p/string()
};

(: If date not available, set to 1700 :)
declare function idx:get-notAfter($date as element()?) {
    if ($date/@when != ('', '0000-00-00')) then 
        $date/@when 
    else if ($date/@to) then 
        $date/@to
    else '1700-01-01'
};

(: If date not available, set to 1200 :)
declare function idx:get-notBefore($date as element()?) {
    if ($date/@when != ('', '0000-00-00')) then 
        $date/@when 
    else if ($date/@from) then 
        $date/@from
    else '1200-01-01'
};

declare function idx:get-genre($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#genre"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};
