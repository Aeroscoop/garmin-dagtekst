import urllib.request
import re
import html
import sys

def strip_tags(text):
    if not text:
        return ""
    # strip HTML tags
    clean = re.sub(r'<[^>]+>', '', text)
    clean = html.unescape(clean)
    clean = clean.replace('\xa0', ' ')
    return clean.strip()

def parse_wol_html(html_str, current_date_str="donderdag 1 oktober", current_iso="2026-10-01"):
    tab_contents = re.findall(r'(<div[^>]*class="[^"]*tabContent[^"]*"[^>]*>.*?)(?=<div[^>]*class="[^"]*tabContent[^"]*"|$)', html_str, re.DOTALL)

    if not tab_contents:
        # Fallback to general search
        tab_contents = [html_str]

    target_block = None
    for block in tab_contents:
        if current_iso in block or current_date_str.lower() in block.lower():
            target_block = block
            break

    if not target_block:
        target_block = tab_contents[0]

    # Extract date header
    date_match = re.search(r'<h2[^>]*>(.*?)</h2>', target_block, re.DOTALL)
    date_title = strip_tags(date_match.group(1)) if date_match else ""

    # Extract theme scripture
    scrp_match = re.search(r'<p[^>]*class="[^"]*themeScrp[^"]*"[^>]*>(.*?)</p>', target_block, re.DOTALL)
    scripture = strip_tags(scrp_match.group(1)) if scrp_match else ""

    # Extract commentary
    com_match = re.search(r'<p[^>]*class="[^"]*sb[^"]*"[^>]*>(.*?)</p>', target_block, re.DOTALL)
    commentary = strip_tags(com_match.group(1)) if com_match else ""

    is_today = (current_date_str.lower() in date_title.lower()) or (current_iso in target_block)

    return {
        'dateTitle': date_title,
        'scripture': scripture,
        'commentary': commentary,
        'isToday': is_today
    }

def test_live():
    print("Testing live WOL site (https://wol.jw.org/nl)...")
    req = urllib.request.Request('https://wol.jw.org/nl', headers={'User-Agent': 'Mozilla/5.0'})
    try:
        content = urllib.request.urlopen(req).read().decode('utf-8')
        result = parse_wol_html(content, "donderdag 1 oktober", "2026-10-01")
        print("Date Title:", result['dateTitle'])
        print("Scripture:", result['scripture'])
        print("Commentary preview:", result['commentary'][:100] + "...")
        print("Is Today Match:", result['isToday'])

        assert len(result['dateTitle']) > 0, "Date title should not be empty"
        assert len(result['scripture']) > 0, "Scripture should not be empty"
        assert len(result['commentary']) > 0, "Commentary should not be empty"
        print("LIVE TEST PASSED!")
    except Exception as e:
        print("LIVE TEST FAILED:", e)
        sys.exit(1)

def test_offline_sample():
    print("\nTesting offline HTML sample...")
    sample_html = '''
    <div class="tabContent" data-date="2026-10-01T00:00:00.000Z">
        <header>
            <h2 id="p2" data-pid="2">donderdag 1&nbsp;oktober</h2>
        </header>
        <p id="p3" data-pid="3" class="themeScrp"><em>Ik zal blijven uitzien naar Jehovah. &mdash;</em>&nbsp;<a href="#"><em>Micha 7:7</em></a><em>.</em></p>
        <div class="bodyTxt">
            <p id="p4" data-pid="4" class="sb">We krijgen vaak instructies die ons helpen in onze dienst voor Jehovah.</p>
        </div>
    </div>
    '''
    result = parse_wol_html(sample_html, "donderdag 1 oktober", "2026-10-01")
    assert result['dateTitle'] == "donderdag 1 oktober", f"Expected 'donderdag 1 oktober', got '{result['dateTitle']}'"
    assert "Micha 7:7" in result['scripture'], "Scripture should contain Micha 7:7"
    assert "instructies" in result['commentary'], "Commentary should contain 'instructies'"
    assert result['isToday'] == True, "isToday should be True"
    print("OFFLINE TEST PASSED!")

if __name__ == '__main__':
    test_offline_sample()
    test_live()
