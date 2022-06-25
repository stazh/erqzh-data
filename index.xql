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
                idx:get-notAfter(head($header//tei:sourceDesc//tei:history/tei:origin/tei:origDate))
            case "notBefore" return
                idx:get-notBefore(
                    head((
                        $header//tei:sourceDesc/tei:msDesc/tei:msContents/tei:msItem//tei:origDate,
                        $header//tei:sourceDesc//tei:history/tei:origin/tei:origDate
                    ))
                )
            case "type" return
                if ($root/@type=('volinfo', 'biblio') or empty($root//tei:body/*)) then 
                    'variant'
                else if ($root/@type='introduction') then
                    'introduction'
                else 
                    'document'
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
    try {
        if ($date/@when != ('', '0000-00-00')) then 
            idx:normalize-date($date/@when)
        else if ($date/@to) then 
            idx:normalize-date($date/@to)
        else xs:date('1000-01-01')
    } catch * {
        xs:date('1000-01-01')
    }
};

(: If date not available, set to 1200 :)
declare function idx:get-notBefore($date as element()?) {
    try {
        if ($date/@when != ('', '0000-00-00')) then 
            idx:normalize-date($date/@when)
        else if ($date/@from) then 
            idx:normalize-date($date/@from)
        else xs:date('1000-01-01')
    } catch * {
        xs:date('1000-01-01')
    }
};

declare function idx:normalize-date($date as xs:string) {
    if (matches($date, "^\d{4}-\d{2}$")) then
        xs:date($date || "-01")
    else if (matches($date, "^\d{4}$")) then
        xs:date($date || "-01-01")
    else
        xs:date($date)
};

declare function idx:get-genre($header as element()?) {
    for $target in $header//tei:textClass/tei:catRef[@scheme="#genre"]/@target
    let $category := id(substring($target, 2), doc($idx:app-root || "/data/taxonomy.xml"))
    return
        $category/ancestor-or-self::tei:category[parent::tei:category]/tei:catDesc
};
