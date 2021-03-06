require 'lib/xml_format'
require 'lib/tags'
require 'pp'

#----------------------------------------------------------------

class XMLFormatTests < Test::Unit::TestCase
  include Tags
  include XMLFormat

  tag :quick, :infrastructure

  def test_xml_parse
    io = StringIO.new(BASIC_TESTS_DD)
    metadata = read_xml(io)
    assert_equal(128, metadata.superblock.data_block_size)
    assert_equal(16384, metadata.devices[0].mapped_blocks)
    assert_equal(2, metadata.devices.length)
  end

  def read_write_cycle(str)
    io = StringIO.new(str)
    metadata = read_xml(io)
    io = StringIO.new('')
    write_xml(metadata, io)
    assert_equal(str, io.string)
  end

  def test_xml_write
    read_write_cycle(BASIC_TESTS_DD)
    read_write_cycle(BASIC_TESTS_DT)
  end
end

BASIC_TESTS_DD = <<END
<superblock uuid="" time="1" transaction="0" data_block_size="128" nr_data_blocks="100000">
  <device dev_id="0" mapped_blocks="16384" transaction="0" creation_time="0" snap_time="1">
    <range_mapping origin_begin="0" data_begin="0" length="16384" time="1"/>
  </device>
  <device dev_id="1" mapped_blocks="16384" transaction="0" creation_time="1" snap_time="1">
    <range_mapping origin_begin="0" data_begin="16384" length="16384" time="1"/>
  </device>
</superblock>
END

BASIC_TESTS_DT = <<END
<superblock uuid="" time="1" transaction="0" data_block_size="128" nr_data_blocks="100000">
  <device dev_id="0" mapped_blocks="9133" transaction="0" creation_time="0" snap_time="1">
    <range_mapping origin_begin="0" data_begin="9004" length="12" time="1"/>
    <range_mapping origin_begin="12" data_begin="7862" length="2" time="1"/>
    <single_mapping origin_block="14" data_block="7530" time="1"/>
    <range_mapping origin_begin="15" data_begin="3480" length="14" time="1"/>
    <range_mapping origin_begin="29" data_begin="1169" length="32" time="1"/>
    <range_mapping origin_begin="61" data_begin="0" length="65" time="1"/>
    <range_mapping origin_begin="126" data_begin="845" length="2" time="1"/>
    <range_mapping origin_begin="1278" data_begin="2999" length="65" time="1"/>
    <range_mapping origin_begin="1343" data_begin="7864" length="49" time="1"/>
    <range_mapping origin_begin="1407" data_begin="8804" length="65" time="1"/>
    <range_mapping origin_begin="1533" data_begin="8552" length="65" time="1"/>
    <range_mapping origin_begin="1743" data_begin="5659" length="45" time="1"/>
    <range_mapping origin_begin="1788" data_begin="6112" length="20" time="1"/>
    <range_mapping origin_begin="1808" data_begin="8617" length="32" time="1"/>
    <range_mapping origin_begin="1915" data_begin="65" length="65" time="1"/>
    <range_mapping origin_begin="1980" data_begin="2511" length="20" time="1"/>
    <range_mapping origin_begin="2000" data_begin="2726" length="24" time="1"/>
    <range_mapping origin_begin="2024" data_begin="3064" length="21" time="1"/>
    <range_mapping origin_begin="2045" data_begin="4388" length="3" time="1"/>
    <single_mapping origin_block="2048" data_block="4387" time="1"/>
    <range_mapping origin_begin="2049" data_begin="4391" length="30" time="1"/>
    <range_mapping origin_begin="2079" data_begin="8344" length="4" time="1"/>
    <range_mapping origin_begin="2927" data_begin="3707" length="65" time="1"/>
    <range_mapping origin_begin="2992" data_begin="6770" length="15" time="1"/>
    <range_mapping origin_begin="3007" data_begin="3979" length="65" time="1"/>
    <range_mapping origin_begin="3072" data_begin="4421" length="64" time="1"/>
    <range_mapping origin_begin="3283" data_begin="5704" length="3" time="1"/>
    <range_mapping origin_begin="3286" data_begin="5268" length="65" time="1"/>
    <range_mapping origin_begin="3351" data_begin="7062" length="33" time="1"/>
    <range_mapping origin_begin="3389" data_begin="130" length="65" time="1"/>
    <range_mapping origin_begin="3581" data_begin="4044" length="65" time="1"/>
    <range_mapping origin_begin="3829" data_begin="2531" length="65" time="1"/>
    <range_mapping origin_begin="3894" data_begin="6132" length="58" time="1"/>
    <range_mapping origin_begin="3965" data_begin="7095" length="34" time="1"/>
    <range_mapping origin_begin="3999" data_begin="6190" length="28" time="1"/>
    <range_mapping origin_begin="4027" data_begin="5707" length="15" time="1"/>
    <range_mapping origin_begin="4042" data_begin="3494" length="23" time="1"/>
    <range_mapping origin_begin="4065" data_begin="2596" length="65" time="1"/>
    <range_mapping origin_begin="4130" data_begin="4837" length="29" time="1"/>
    <range_mapping origin_begin="4941" data_begin="7913" length="50" time="1"/>
    <range_mapping origin_begin="4991" data_begin="6326" length="65" time="1"/>
    <range_mapping origin_begin="5056" data_begin="8649" length="31" time="1"/>
    <range_mapping origin_begin="5087" data_begin="5372" length="20" time="1"/>
    <range_mapping origin_begin="5107" data_begin="3085" length="65" time="1"/>
    <range_mapping origin_begin="5172" data_begin="7335" length="9" time="1"/>
    <range_mapping origin_begin="5311" data_begin="7963" length="38" time="1"/>
    <range_mapping origin_begin="5349" data_begin="1201" length="65" time="1"/>
    <range_mapping origin_begin="5414" data_begin="9114" length="18" time="1"/>
    <range_mapping origin_begin="5485" data_begin="8001" length="65" time="1"/>
    <range_mapping origin_begin="5591" data_begin="7129" length="39" time="1"/>
    <range_mapping origin_begin="5630" data_begin="4485" length="65" time="1"/>
    <range_mapping origin_begin="5791" data_begin="4866" length="65" time="1"/>
    <range_mapping origin_begin="5856" data_begin="7268" length="12" time="1"/>
    <range_mapping origin_begin="5868" data_begin="6391" length="2" time="1"/>
    <range_mapping origin_begin="5870" data_begin="6585" length="16" time="1"/>
    <range_mapping origin_begin="5886" data_begin="3772" length="65" time="1"/>
    <range_mapping origin_begin="5951" data_begin="6948" length="41" time="1"/>
    <range_mapping origin_begin="5992" data_begin="9016" length="11" time="1"/>
    <range_mapping origin_begin="6003" data_begin="4109" length="128" time="1"/>
    <range_mapping origin_begin="6131" data_begin="6989" length="4" time="1"/>
    <range_mapping origin_begin="6135" data_begin="1266" length="65" time="1"/>
    <range_mapping origin_begin="6200" data_begin="9027" length="8" time="1"/>
    <range_mapping origin_begin="6397" data_begin="7344" length="65" time="1"/>
    <range_mapping origin_begin="6495" data_begin="195" length="65" time="1"/>
    <range_mapping origin_begin="6620" data_begin="8066" length="11" time="1"/>
    <range_mapping origin_begin="6631" data_begin="7409" length="5" time="1"/>
    <range_mapping origin_begin="6636" data_begin="4931" length="64" time="1"/>
    <range_mapping origin_begin="6700" data_begin="7738" length="2" time="1"/>
    <range_mapping origin_begin="6783" data_begin="8141" length="65" time="1"/>
    <range_mapping origin_begin="6862" data_begin="3517" length="65" time="1"/>
    <range_mapping origin_begin="6927" data_begin="7168" length="32" time="1"/>
    <range_mapping origin_begin="6959" data_begin="6790" length="65" time="1"/>
    <range_mapping origin_begin="7024" data_begin="7414" length="62" time="1"/>
    <range_mapping origin_begin="7086" data_begin="7628" length="12" time="1"/>
    <range_mapping origin_begin="7099" data_begin="1331" length="65" time="1"/>
    <range_mapping origin_begin="7164" data_begin="3582" length="2" time="1"/>
    <range_mapping origin_begin="7166" data_begin="847" length="65" time="1"/>
    <single_mapping origin_block="7231" data_block="9132" time="1"/>
    <range_mapping origin_begin="7260" data_begin="7200" length="65" time="1"/>
    <range_mapping origin_begin="7325" data_begin="8680" length="35" time="1"/>
    <range_mapping origin_begin="7360" data_begin="8722" length="40" time="1"/>
    <range_mapping origin_begin="7421" data_begin="6601" length="41" time="1"/>
    <range_mapping origin_begin="7462" data_begin="3837" length="65" time="1"/>
    <range_mapping origin_begin="7527" data_begin="8348" length="25" time="1"/>
    <range_mapping origin_begin="7615" data_begin="1396" length="121" time="1"/>
    <range_mapping origin_begin="7736" data_begin="2136" length="6" time="1"/>
    <range_mapping origin_begin="7742" data_begin="7740" length="16" time="1"/>
    <range_mapping origin_begin="7758" data_begin="8077" length="16" time="1"/>
    <range_mapping origin_begin="7863" data_begin="7756" length="24" time="1"/>
    <range_mapping origin_begin="7887" data_begin="2142" length="65" time="1"/>
    <range_mapping origin_begin="7952" data_begin="5722" length="48" time="1"/>
    <range_mapping origin_begin="8000" data_begin="6993" length="15" time="1"/>
    <range_mapping origin_begin="8015" data_begin="260" length="65" time="1"/>
    <range_mapping origin_begin="8080" data_begin="3902" length="23" time="1"/>
    <range_mapping origin_begin="8103" data_begin="5392" length="16" time="1"/>
    <range_mapping origin_begin="8119" data_begin="325" length="65" time="1"/>
    <range_mapping origin_begin="8184" data_begin="2207" length="64" time="1"/>
    <range_mapping origin_begin="8248" data_begin="3584" length="8" time="1"/>
    <range_mapping origin_begin="8379" data_begin="5408" length="65" time="1"/>
    <range_mapping origin_begin="8585" data_begin="3150" length="65" time="1"/>
    <range_mapping origin_begin="8650" data_begin="4550" length="61" time="1"/>
    <range_mapping origin_begin="8959" data_begin="5770" length="65" time="1"/>
    <range_mapping origin_begin="9083" data_begin="1517" length="65" time="1"/>
    <range_mapping origin_begin="9148" data_begin="4611" length="4" time="1"/>
    <range_mapping origin_begin="9152" data_begin="5835" length="57" time="1"/>
    <range_mapping origin_begin="9212" data_begin="5892" length="23" time="1"/>
    <range_mapping origin_begin="9235" data_begin="5917" length="22" time="1"/>
    <range_mapping origin_begin="9257" data_begin="5915" length="2" time="1"/>
    <range_mapping origin_begin="9259" data_begin="5939" length="18" time="1"/>
    <range_mapping origin_begin="9343" data_begin="5473" length="65" time="1"/>
    <range_mapping origin_begin="9531" data_begin="8206" length="65" time="1"/>
    <range_mapping origin_begin="9678" data_begin="4995" length="13" time="1"/>
    <range_mapping origin_begin="9691" data_begin="5333" length="32" time="1"/>
    <range_mapping origin_begin="9723" data_begin="2661" length="65" time="1"/>
    <range_mapping origin_begin="9809" data_begin="8869" length="65" time="1"/>
    <range_mapping origin_begin="9943" data_begin="7280" length="40" time="1"/>
    <range_mapping origin_begin="9983" data_begin="5957" length="65" time="1"/>
    <range_mapping origin_begin="10093" data_begin="7640" length="28" time="1"/>
    <range_mapping origin_begin="10121" data_begin="7008" length="54" time="1"/>
    <range_mapping origin_begin="10175" data_begin="5008" length="129" time="1"/>
    <range_mapping origin_begin="10475" data_begin="2271" length="20" time="1"/>
    <range_mapping origin_begin="10495" data_begin="390" length="65" time="1"/>
    <range_mapping origin_begin="10645" data_begin="6393" length="65" time="1"/>
    <range_mapping origin_begin="10710" data_begin="7668" length="5" time="1"/>
    <range_mapping origin_begin="10715" data_begin="3925" length="27" time="1"/>
    <range_mapping origin_begin="10742" data_begin="2750" length="65" time="1"/>
    <range_mapping origin_begin="10807" data_begin="5365" length="7" time="1"/>
    <range_mapping origin_begin="11002" data_begin="5137" length="65" time="1"/>
    <range_mapping origin_begin="11067" data_begin="6458" length="29" time="1"/>
    <range_mapping origin_begin="11096" data_begin="8934" length="7" time="1"/>
    <range_mapping origin_begin="11103" data_begin="7531" length="32" time="1"/>
    <range_mapping origin_begin="11135" data_begin="7476" length="24" time="1"/>
    <range_mapping origin_begin="11159" data_begin="2815" length="6" time="1"/>
    <range_mapping origin_begin="11165" data_begin="2291" length="65" time="1"/>
    <range_mapping origin_begin="11230" data_begin="3592" length="21" time="1"/>
    <range_mapping origin_begin="11251" data_begin="1582" length="77" time="1"/>
    <range_mapping origin_begin="11567" data_begin="4615" length="65" time="1"/>
    <range_mapping origin_begin="11647" data_begin="4680" length="100" time="1"/>
    <range_mapping origin_begin="11747" data_begin="8093" length="8" time="1"/>
    <range_mapping origin_begin="11755" data_begin="6487" length="15" time="1"/>
    <range_mapping origin_begin="11770" data_begin="1659" length="65" time="1"/>
    <range_mapping origin_begin="11853" data_begin="8373" length="17" time="1"/>
    <range_mapping origin_begin="11870" data_begin="6502" length="12" time="1"/>
    <range_mapping origin_begin="11882" data_begin="6022" length="65" time="1"/>
    <range_mapping origin_begin="11947" data_begin="6642" length="21" time="1"/>
    <range_mapping origin_begin="11968" data_begin="6855" length="23" time="1"/>
    <range_mapping origin_begin="11991" data_begin="1724" length="35" time="1"/>
    <range_mapping origin_begin="12026" data_begin="912" length="65" time="1"/>
    <range_mapping origin_begin="12091" data_begin="4237" length="36" time="1"/>
    <range_mapping origin_begin="12127" data_begin="3215" length="65" time="1"/>
    <range_mapping origin_begin="12192" data_begin="8715" length="7" time="1"/>
    <range_mapping origin_begin="12199" data_begin="6218" length="72" time="1"/>
    <range_mapping origin_begin="12271" data_begin="3280" length="16" time="1"/>
    <range_mapping origin_begin="12287" data_begin="1759" length="65" time="1"/>
    <range_mapping origin_begin="12857" data_begin="3296" length="65" time="1"/>
    <range_mapping origin_begin="12923" data_begin="8271" length="28" time="1"/>
    <range_mapping origin_begin="12951" data_begin="6514" length="65" time="1"/>
    <range_mapping origin_begin="13021" data_begin="2356" length="65" time="1"/>
    <range_mapping origin_begin="13086" data_begin="7500" length="30" time="1"/>
    <range_mapping origin_begin="13181" data_begin="8390" length="62" time="1"/>
    <range_mapping origin_begin="13243" data_begin="455" length="65" time="1"/>
    <range_mapping origin_begin="13308" data_begin="8941" length="60" time="1"/>
    <range_mapping origin_begin="13435" data_begin="9035" length="65" time="1"/>
    <range_mapping origin_begin="13535" data_begin="7563" length="65" time="1"/>
    <range_mapping origin_begin="13600" data_begin="9100" length="14" time="1"/>
    <range_mapping origin_begin="13644" data_begin="8762" length="27" time="1"/>
    <range_mapping origin_begin="13671" data_begin="8452" length="65" time="1"/>
    <range_mapping origin_begin="13759" data_begin="5538" length="62" time="1"/>
    <single_mapping origin_block="13821" data_block="4780" time="1"/>
    <range_mapping origin_begin="13822" data_begin="977" length="65" time="1"/>
    <range_mapping origin_begin="13887" data_begin="6878" length="63" time="1"/>
    <range_mapping origin_begin="13951" data_begin="5600" length="44" time="1"/>
    <range_mapping origin_begin="13995" data_begin="3952" length="8" time="1"/>
    <range_mapping origin_begin="14003" data_begin="1824" length="109" time="1"/>
    <range_mapping origin_begin="14112" data_begin="2821" length="32" time="1"/>
    <range_mapping origin_begin="14144" data_begin="4273" length="58" time="1"/>
    <range_mapping origin_begin="14202" data_begin="9001" length="3" time="1"/>
    <range_mapping origin_begin="14205" data_begin="6663" length="2" time="1"/>
    <range_mapping origin_begin="14207" data_begin="520" length="65" time="1"/>
    <range_mapping origin_begin="14272" data_begin="1042" length="55" time="1"/>
    <range_mapping origin_begin="14327" data_begin="585" length="35" time="1"/>
    <range_mapping origin_begin="14362" data_begin="815" length="30" time="1"/>
    <range_mapping origin_begin="14392" data_begin="6785" length="5" time="1"/>
    <range_mapping origin_begin="14397" data_begin="7265" length="3" time="1"/>
    <range_mapping origin_begin="14443" data_begin="6665" length="65" time="1"/>
    <range_mapping origin_begin="14702" data_begin="7673" length="65" time="1"/>
    <range_mapping origin_begin="14799" data_begin="8789" length="15" time="1"/>
    <range_mapping origin_begin="14814" data_begin="4331" length="17" time="1"/>
    <range_mapping origin_begin="14831" data_begin="1933" length="65" time="1"/>
    <range_mapping origin_begin="14896" data_begin="5644" length="15" time="1"/>
    <single_mapping origin_block="14911" data_block="6941" time="1"/>
    <range_mapping origin_begin="14912" data_begin="8101" length="40" time="1"/>
    <range_mapping origin_begin="14975" data_begin="8299" length="44" time="1"/>
    <range_mapping origin_begin="15019" data_begin="7320" length="15" time="1"/>
    <range_mapping origin_begin="15034" data_begin="6579" length="5" time="1"/>
    <range_mapping origin_begin="15039" data_begin="620" length="65" time="1"/>
    <range_mapping origin_begin="15104" data_begin="4781" length="47" time="1"/>
    <range_mapping origin_begin="15151" data_begin="2421" length="65" time="1"/>
    <range_mapping origin_begin="15216" data_begin="8517" length="35" time="1"/>
    <range_mapping origin_begin="15251" data_begin="6290" length="10" time="1"/>
    <range_mapping origin_begin="15261" data_begin="3361" length="65" time="1"/>
    <range_mapping origin_begin="15326" data_begin="4828" length="9" time="1"/>
    <range_mapping origin_begin="15335" data_begin="3960" length="3" time="1"/>
    <range_mapping origin_begin="15338" data_begin="3613" length="20" time="1"/>
    <range_mapping origin_begin="15358" data_begin="1998" length="65" time="1"/>
    <single_mapping origin_block="15423" data_block="8343" time="1"/>
    <range_mapping origin_begin="15483" data_begin="7780" length="20" time="1"/>
    <range_mapping origin_begin="15503" data_begin="6730" length="40" time="1"/>
    <range_mapping origin_begin="15543" data_begin="5202" length="65" time="1"/>
    <range_mapping origin_begin="15608" data_begin="6942" length="6" time="1"/>
    <single_mapping origin_block="15614" data_block="5267" time="1"/>
    <range_mapping origin_begin="15615" data_begin="2853" length="65" time="1"/>
    <range_mapping origin_begin="15680" data_begin="3426" length="54" time="1"/>
    <range_mapping origin_begin="15734" data_begin="3633" length="46" time="1"/>
    <range_mapping origin_begin="15780" data_begin="6087" length="22" time="1"/>
    <range_mapping origin_begin="15802" data_begin="3963" length="13" time="1"/>
    <range_mapping origin_begin="15815" data_begin="2063" length="44" time="1"/>
    <range_mapping origin_begin="15859" data_begin="685" length="65" time="1"/>
    <range_mapping origin_begin="15924" data_begin="2918" length="10" time="1"/>
    <range_mapping origin_begin="15934" data_begin="3679" length="2" time="1"/>
    <range_mapping origin_begin="15936" data_begin="6300" length="19" time="1"/>
    <range_mapping origin_begin="15981" data_begin="7800" length="62" time="1"/>
    <range_mapping origin_begin="16043" data_begin="2928" length="47" time="1"/>
    <range_mapping origin_begin="16090" data_begin="750" length="65" time="1"/>
    <range_mapping origin_begin="16155" data_begin="2975" length="9" time="1"/>
    <range_mapping origin_begin="16164" data_begin="6109" length="3" time="1"/>
    <range_mapping origin_begin="16167" data_begin="6319" length="7" time="1"/>
    <range_mapping origin_begin="16174" data_begin="4348" length="39" time="1"/>
    <range_mapping origin_begin="16213" data_begin="3681" length="26" time="1"/>
    <range_mapping origin_begin="16239" data_begin="2984" length="15" time="1"/>
    <range_mapping origin_begin="16254" data_begin="2107" length="29" time="1"/>
    <range_mapping origin_begin="16283" data_begin="1097" length="72" time="1"/>
    <range_mapping origin_begin="16355" data_begin="2486" length="25" time="1"/>
    <range_mapping origin_begin="16380" data_begin="3976" length="3" time="1"/>
    <single_mapping origin_block="16383" data_block="6584" time="1"/>
  </device>
  <device dev_id="1" mapped_blocks="10964" transaction="0" creation_time="1" snap_time="1">
    <range_mapping origin_begin="0" data_begin="9004" length="8" time="1"/>
    <range_mapping origin_begin="8" data_begin="13177" length="23" time="1"/>
    <range_mapping origin_begin="31" data_begin="9867" length="15" time="1"/>
    <range_mapping origin_begin="46" data_begin="9133" length="82" time="1"/>
    <range_mapping origin_begin="507" data_begin="17082" length="65" time="1"/>
    <range_mapping origin_begin="702" data_begin="9882" length="65" time="1"/>
    <range_mapping origin_begin="767" data_begin="14645" length="44" time="1"/>
    <range_mapping origin_begin="1262" data_begin="17211" length="65" time="1"/>
    <range_mapping origin_begin="1327" data_begin="3048" length="16" time="1"/>
    <range_mapping origin_begin="1343" data_begin="7864" length="32" time="1"/>
    <range_mapping origin_begin="1375" data_begin="12113" length="65" time="1"/>
    <range_mapping origin_begin="1440" data_begin="8837" length="32" time="1"/>
    <range_mapping origin_begin="1514" data_begin="15989" length="65" time="1"/>
    <range_mapping origin_begin="1579" data_begin="8598" length="19" time="1"/>
    <range_mapping origin_begin="1743" data_begin="5659" length="45" time="1"/>
    <range_mapping origin_begin="1788" data_begin="6112" length="20" time="1"/>
    <range_mapping origin_begin="1808" data_begin="8617" length="32" time="1"/>
    <range_mapping origin_begin="1887" data_begin="10730" length="65" time="1"/>
    <range_mapping origin_begin="1952" data_begin="17036" length="30" time="1"/>
    <range_mapping origin_begin="1982" data_begin="2513" length="18" time="1"/>
    <range_mapping origin_begin="2000" data_begin="2726" length="24" time="1"/>
    <range_mapping origin_begin="2024" data_begin="3064" length="13" time="1"/>
    <range_mapping origin_begin="2037" data_begin="11601" length="65" time="1"/>
    <range_mapping origin_begin="2102" data_begin="13886" length="6" time="1"/>
    <range_mapping origin_begin="2730" data_begin="14973" length="65" time="1"/>
    <range_mapping origin_begin="2814" data_begin="9215" length="65" time="1"/>
    <range_mapping origin_begin="2927" data_begin="3707" length="2" time="1"/>
    <range_mapping origin_begin="2929" data_begin="15677" length="65" time="1"/>
    <range_mapping origin_begin="2994" data_begin="6772" length="13" time="1"/>
    <range_mapping origin_begin="3007" data_begin="3979" length="30" time="1"/>
    <range_mapping origin_begin="3037" data_begin="13689" length="2" time="1"/>
    <range_mapping origin_begin="3039" data_begin="13436" length="65" time="1"/>
    <range_mapping origin_begin="3104" data_begin="4453" length="31" time="1"/>
    <range_mapping origin_begin="3135" data_begin="17682" length="65" time="1"/>
    <range_mapping origin_begin="3283" data_begin="5704" length="3" time="1"/>
    <range_mapping origin_begin="3286" data_begin="5268" length="65" time="1"/>
    <range_mapping origin_begin="3351" data_begin="7062" length="33" time="1"/>
    <range_mapping origin_begin="3389" data_begin="130" length="2" time="1"/>
    <range_mapping origin_begin="3391" data_begin="16565" length="65" time="1"/>
    <range_mapping origin_begin="3477" data_begin="10795" length="65" time="1"/>
    <single_mapping origin_block="3581" data_block="4044" time="1"/>
    <range_mapping origin_begin="3582" data_begin="16664" length="65" time="1"/>
    <range_mapping origin_begin="3774" data_begin="15151" length="65" time="1"/>
    <range_mapping origin_begin="3839" data_begin="15763" length="61" time="1"/>
    <range_mapping origin_begin="3900" data_begin="6138" length="52" time="1"/>
    <range_mapping origin_begin="3964" data_begin="16806" length="66" time="1"/>
    <range_mapping origin_begin="4030" data_begin="5710" length="12" time="1"/>
    <range_mapping origin_begin="4042" data_begin="3494" length="9" time="1"/>
    <range_mapping origin_begin="4051" data_begin="11437" length="65" time="1"/>
    <range_mapping origin_begin="4116" data_begin="16054" length="38" time="1"/>
    <range_mapping origin_begin="4154" data_begin="16729" length="2" time="1"/>
    <range_mapping origin_begin="4156" data_begin="4863" length="3" time="1"/>
    <range_mapping origin_begin="4941" data_begin="7913" length="50" time="1"/>
    <range_mapping origin_begin="4991" data_begin="6326" length="30" time="1"/>
    <range_mapping origin_begin="5021" data_begin="16365" length="11" time="1"/>
    <range_mapping origin_begin="5032" data_begin="12178" length="65" time="1"/>
    <range_mapping origin_begin="5097" data_begin="13355" length="45" time="1"/>
    <range_mapping origin_begin="5142" data_begin="14315" length="26" time="1"/>
    <range_mapping origin_begin="5168" data_begin="3146" length="4" time="1"/>
    <range_mapping origin_begin="5172" data_begin="7335" length="9" time="1"/>
    <range_mapping origin_begin="5311" data_begin="7963" length="38" time="1"/>
    <range_mapping origin_begin="5349" data_begin="1201" length="18" time="1"/>
    <range_mapping origin_begin="5367" data_begin="16872" length="65" time="1"/>
    <range_mapping origin_begin="5485" data_begin="8001" length="65" time="1"/>
    <range_mapping origin_begin="5591" data_begin="7129" length="35" time="1"/>
    <range_mapping origin_begin="5626" data_begin="17466" length="65" time="1"/>
    <range_mapping origin_begin="5691" data_begin="4546" length="4" time="1"/>
    <range_mapping origin_begin="5791" data_begin="4866" length="54" time="1"/>
    <range_mapping origin_begin="5845" data_begin="16937" length="10" time="1"/>
    <range_mapping origin_begin="5855" data_begin="14223" length="65" time="1"/>
    <range_mapping origin_begin="5920" data_begin="15038" length="16" time="1"/>
    <range_mapping origin_begin="5936" data_begin="3822" length="2" time="1"/>
    <range_mapping origin_begin="5938" data_begin="17276" length="37" time="1"/>
    <range_mapping origin_begin="5975" data_begin="16947" length="24" time="1"/>
    <range_mapping origin_begin="5999" data_begin="15824" length="47" time="1"/>
    <range_mapping origin_begin="6046" data_begin="10860" length="65" time="1"/>
    <range_mapping origin_begin="6111" data_begin="15614" length="8" time="1"/>
    <range_mapping origin_begin="6119" data_begin="11666" length="23" time="1"/>
    <range_mapping origin_begin="6142" data_begin="9280" length="65" time="1"/>
    <single_mapping origin_block="6207" data_block="17747" time="1"/>
    <range_mapping origin_begin="6393" data_begin="17843" length="65" time="1"/>
    <range_mapping origin_begin="6458" data_begin="7405" length="4" time="1"/>
    <range_mapping origin_begin="6495" data_begin="195" length="65" time="1"/>
    <range_mapping origin_begin="6575" data_begin="17531" length="65" time="1"/>
    <range_mapping origin_begin="6640" data_begin="4935" length="13" time="1"/>
    <single_mapping origin_block="6653" data_block="17596" time="1"/>
    <single_mapping origin_block="6654" data_block="15054" time="1"/>
    <range_mapping origin_begin="6655" data_begin="12581" length="65" time="1"/>
    <range_mapping origin_begin="6755" data_begin="10925" length="65" time="1"/>
    <range_mapping origin_begin="6820" data_begin="16230" length="13" time="1"/>
    <range_mapping origin_begin="6833" data_begin="13501" length="65" time="1"/>
    <single_mapping origin_block="6898" data_block="17748" time="1"/>
    <range_mapping origin_begin="6899" data_begin="16441" length="65" time="1"/>
    <range_mapping origin_begin="6964" data_begin="6795" length="60" time="1"/>
    <range_mapping origin_begin="7024" data_begin="7414" length="14" time="1"/>
    <range_mapping origin_begin="7038" data_begin="17749" length="28" time="1"/>
    <range_mapping origin_begin="7066" data_begin="10990" length="57" time="1"/>
    <range_mapping origin_begin="7123" data_begin="9345" length="65" time="1"/>
    <range_mapping origin_begin="7188" data_begin="14341" length="32" time="1"/>
    <range_mapping origin_begin="7220" data_begin="16731" length="8" time="1"/>
    <range_mapping origin_begin="7228" data_begin="17599" length="3" time="1"/>
    <single_mapping origin_block="7231" data_block="9132" time="1"/>
    <range_mapping origin_begin="7260" data_begin="7200" length="35" time="1"/>
    <range_mapping origin_begin="7295" data_begin="16376" length="65" time="1"/>
    <range_mapping origin_begin="7360" data_begin="17313" length="47" time="1"/>
    <range_mapping origin_begin="7407" data_begin="11502" length="65" time="1"/>
    <range_mapping origin_begin="7472" data_begin="17066" length="16" time="1"/>
    <range_mapping origin_begin="7488" data_begin="3863" length="30" time="1"/>
    <range_mapping origin_begin="7518" data_begin="13691" length="33" time="1"/>
    <range_mapping origin_begin="7551" data_begin="12243" length="65" time="1"/>
    <range_mapping origin_begin="7616" data_begin="16092" length="31" time="1"/>
    <range_mapping origin_begin="7647" data_begin="12646" length="32" time="1"/>
    <range_mapping origin_begin="7679" data_begin="11689" length="65" time="1"/>
    <range_mapping origin_begin="7744" data_begin="7742" length="14" time="1"/>
    <range_mapping origin_begin="7758" data_begin="8077" length="16" time="1"/>
    <range_mapping origin_begin="7842" data_begin="13200" length="65" time="1"/>
    <range_mapping origin_begin="7907" data_begin="13400" length="26" time="1"/>
    <range_mapping origin_begin="7933" data_begin="11047" length="65" time="1"/>
    <range_mapping origin_begin="7998" data_begin="17908" length="16" time="1"/>
    <range_mapping origin_begin="8014" data_begin="13724" length="49" time="1"/>
    <range_mapping origin_begin="8063" data_begin="11754" length="16" time="1"/>
    <range_mapping origin_begin="8079" data_begin="9947" length="65" time="1"/>
    <range_mapping origin_begin="8144" data_begin="12308" length="43" time="1"/>
    <range_mapping origin_begin="8187" data_begin="11112" length="65" time="1"/>
    <range_mapping origin_begin="8252" data_begin="12351" length="2" time="1"/>
    <single_mapping origin_block="8254" data_block="13426" time="1"/>
    <single_mapping origin_block="8255" data_block="16739" time="1"/>
    <range_mapping origin_begin="8379" data_begin="5408" length="65" time="1"/>
    <range_mapping origin_begin="8585" data_begin="3150" length="65" time="1"/>
    <range_mapping origin_begin="8650" data_begin="4550" length="61" time="1"/>
    <range_mapping origin_begin="8942" data_begin="14373" length="65" time="1"/>
    <range_mapping origin_begin="9007" data_begin="5818" length="17" time="1"/>
    <range_mapping origin_begin="9083" data_begin="1517" length="47" time="1"/>
    <range_mapping origin_begin="9130" data_begin="13566" length="17" time="1"/>
    <range_mapping origin_begin="9147" data_begin="12353" length="65" time="1"/>
    <range_mapping origin_begin="9212" data_begin="5892" length="23" time="1"/>
    <range_mapping origin_begin="9235" data_begin="5917" length="22" time="1"/>
    <range_mapping origin_begin="9257" data_begin="5915" length="2" time="1"/>
    <range_mapping origin_begin="9259" data_begin="5939" length="4" time="1"/>
    <range_mapping origin_begin="9263" data_begin="14855" length="65" time="1"/>
    <range_mapping origin_begin="9343" data_begin="5473" length="65" time="1"/>
    <range_mapping origin_begin="9471" data_begin="14438" length="65" time="1"/>
    <range_mapping origin_begin="9536" data_begin="8211" length="60" time="1"/>
    <range_mapping origin_begin="9647" data_begin="13892" length="65" time="1"/>
    <range_mapping origin_begin="9712" data_begin="15547" length="16" time="1"/>
    <range_mapping origin_begin="9728" data_begin="17147" length="64" time="1"/>
    <range_mapping origin_begin="9809" data_begin="8869" length="8" time="1"/>
    <range_mapping origin_begin="9817" data_begin="17370" length="65" time="1"/>
    <range_mapping origin_begin="9930" data_begin="17777" length="37" time="1"/>
    <range_mapping origin_begin="9967" data_begin="16123" length="65" time="1"/>
    <range_mapping origin_begin="10032" data_begin="16740" length="14" time="1"/>
    <range_mapping origin_begin="10046" data_begin="6020" length="2" time="1"/>
    <range_mapping origin_begin="10093" data_begin="7640" length="14" time="1"/>
    <range_mapping origin_begin="10107" data_begin="10012" length="65" time="1"/>
    <range_mapping origin_begin="10172" data_begin="13773" length="27" time="1"/>
    <range_mapping origin_begin="10199" data_begin="11770" length="65" time="1"/>
    <range_mapping origin_begin="10264" data_begin="12678" length="23" time="1"/>
    <range_mapping origin_begin="10287" data_begin="14288" length="9" time="1"/>
    <range_mapping origin_begin="10296" data_begin="14920" length="4" time="1"/>
    <range_mapping origin_begin="10300" data_begin="17360" length="2" time="1"/>
    <single_mapping origin_block="10302" data_block="17597" time="1"/>
    <range_mapping origin_begin="10303" data_begin="15393" length="65" time="1"/>
    <range_mapping origin_begin="10399" data_begin="15216" length="65" time="1"/>
    <range_mapping origin_begin="10475" data_begin="2271" length="20" time="1"/>
    <range_mapping origin_begin="10495" data_begin="390" length="65" time="1"/>
    <range_mapping origin_begin="10645" data_begin="6393" length="65" time="1"/>
    <range_mapping origin_begin="10710" data_begin="7668" length="5" time="1"/>
    <range_mapping origin_begin="10715" data_begin="3925" length="27" time="1"/>
    <range_mapping origin_begin="10742" data_begin="2750" length="7" time="1"/>
    <range_mapping origin_begin="10749" data_begin="17924" length="64" time="1"/>
    <single_mapping origin_block="10813" data_block="5371" time="1"/>
    <range_mapping origin_begin="10903" data_begin="15281" length="30" time="1"/>
    <range_mapping origin_begin="10933" data_begin="11177" length="65" time="1"/>
    <range_mapping origin_begin="10998" data_begin="13265" length="2" time="1"/>
    <range_mapping origin_begin="11000" data_begin="15563" length="3" time="1"/>
    <range_mapping origin_begin="11003" data_begin="12701" length="65" time="1"/>
    <range_mapping origin_begin="11068" data_begin="13957" length="46" time="1"/>
    <range_mapping origin_begin="11114" data_begin="7542" length="3" time="1"/>
    <range_mapping origin_begin="11117" data_begin="10077" length="65" time="1"/>
    <range_mapping origin_begin="11182" data_begin="12766" length="50" time="1"/>
    <range_mapping origin_begin="11232" data_begin="14003" length="5" time="1"/>
    <single_mapping origin_block="11237" data_block="13814" time="1"/>
    <range_mapping origin_begin="11238" data_begin="14008" length="25" time="1"/>
    <range_mapping origin_begin="11263" data_begin="10142" length="65" time="1"/>
    <range_mapping origin_begin="11487" data_begin="16243" length="26" time="1"/>
    <range_mapping origin_begin="11513" data_begin="9410" length="65" time="1"/>
    <range_mapping origin_begin="11578" data_begin="14924" length="6" time="1"/>
    <range_mapping origin_begin="11584" data_begin="4632" length="48" time="1"/>
    <range_mapping origin_begin="11647" data_begin="4680" length="31" time="1"/>
    <range_mapping origin_begin="11678" data_begin="15742" length="15" time="1"/>
    <range_mapping origin_begin="11693" data_begin="14930" length="18" time="1"/>
    <range_mapping origin_begin="11711" data_begin="11242" length="64" time="1"/>
    <range_mapping origin_begin="11775" data_begin="9475" length="65" time="1"/>
    <range_mapping origin_begin="11849" data_begin="17602" length="51" time="1"/>
    <range_mapping origin_begin="11900" data_begin="16316" length="25" time="1"/>
    <range_mapping origin_begin="11925" data_begin="16188" length="42" time="1"/>
    <range_mapping origin_begin="11967" data_begin="15458" length="24" time="1"/>
    <range_mapping origin_begin="11991" data_begin="13583" length="40" time="1"/>
    <range_mapping origin_begin="12031" data_begin="12816" length="65" time="1"/>
    <range_mapping origin_begin="12096" data_begin="14033" length="42" time="1"/>
    <range_mapping origin_begin="12138" data_begin="14503" length="5" time="1"/>
    <range_mapping origin_begin="12143" data_begin="12881" length="12" time="1"/>
    <range_mapping origin_begin="12155" data_begin="11306" length="34" time="1"/>
    <range_mapping origin_begin="12189" data_begin="9540" length="65" time="1"/>
    <range_mapping origin_begin="12254" data_begin="11835" length="96" time="1"/>
    <range_mapping origin_begin="12350" data_begin="14948" length="2" time="1"/>
    <range_mapping origin_begin="12731" data_begin="15482" length="65" time="1"/>
    <range_mapping origin_begin="12796" data_begin="16506" length="35" time="1"/>
    <range_mapping origin_begin="12831" data_begin="17435" length="31" time="1"/>
    <range_mapping origin_begin="12862" data_begin="3301" length="60" time="1"/>
    <range_mapping origin_begin="12923" data_begin="8271" length="28" time="1"/>
    <range_mapping origin_begin="12951" data_begin="6514" length="40" time="1"/>
    <range_mapping origin_begin="12991" data_begin="9605" length="65" time="1"/>
    <range_mapping origin_begin="13056" data_begin="14689" length="54" time="1"/>
    <range_mapping origin_begin="13110" data_begin="14075" length="65" time="1"/>
    <range_mapping origin_begin="13175" data_begin="14950" length="21" time="1"/>
    <range_mapping origin_begin="13196" data_begin="15566" length="48" time="1"/>
    <range_mapping origin_begin="13244" data_begin="456" length="31" time="1"/>
    <range_mapping origin_begin="13275" data_begin="13623" length="65" time="1"/>
    <range_mapping origin_begin="13340" data_begin="14140" length="35" time="1"/>
    <range_mapping origin_begin="13375" data_begin="14743" length="62" time="1"/>
    <range_mapping origin_begin="13437" data_begin="16630" length="34" time="1"/>
    <range_mapping origin_begin="13471" data_begin="9071" length="29" time="1"/>
    <range_mapping origin_begin="13534" data_begin="17814" length="29" time="1"/>
    <range_mapping origin_begin="13563" data_begin="16754" length="52" time="1"/>
    <range_mapping origin_begin="13615" data_begin="13800" length="14" time="1"/>
    <range_mapping origin_begin="13629" data_begin="12893" length="65" time="1"/>
    <range_mapping origin_begin="13694" data_begin="12418" length="65" time="1"/>
    <range_mapping origin_begin="13759" data_begin="15311" length="28" time="1"/>
    <range_mapping origin_begin="13787" data_begin="14805" length="2" time="1"/>
    <range_mapping origin_begin="13789" data_begin="11931" length="34" time="1"/>
    <range_mapping origin_begin="13823" data_begin="10207" length="65" time="1"/>
    <range_mapping origin_begin="13888" data_begin="6879" length="31" time="1"/>
    <range_mapping origin_begin="13919" data_begin="16971" length="65" time="1"/>
    <range_mapping origin_begin="13984" data_begin="17653" length="29" time="1"/>
    <range_mapping origin_begin="14013" data_begin="14971" length="2" time="1"/>
    <range_mapping origin_begin="14015" data_begin="12958" length="61" time="1"/>
    <range_mapping origin_begin="14076" data_begin="12483" length="3" time="1"/>
    <range_mapping origin_begin="14079" data_begin="10272" length="65" time="1"/>
    <range_mapping origin_begin="14144" data_begin="14175" length="48" time="1"/>
    <range_mapping origin_begin="14192" data_begin="17362" length="8" time="1"/>
    <range_mapping origin_begin="14200" data_begin="13267" length="65" time="1"/>
    <range_mapping origin_begin="14265" data_begin="15757" length="6" time="1"/>
    <range_mapping origin_begin="14271" data_begin="15055" length="31" time="1"/>
    <single_mapping origin_block="14302" data_block="13688" time="1"/>
    <range_mapping origin_begin="14303" data_begin="11340" length="31" time="1"/>
    <range_mapping origin_begin="14334" data_begin="11567" length="34" time="1"/>
    <range_mapping origin_begin="14368" data_begin="13332" length="23" time="1"/>
    <range_mapping origin_begin="14391" data_begin="13427" length="9" time="1"/>
    <range_mapping origin_begin="14400" data_begin="14807" length="48" time="1"/>
    <range_mapping origin_begin="14448" data_begin="6670" length="11" time="1"/>
    <range_mapping origin_begin="14459" data_begin="15086" length="65" time="1"/>
    <range_mapping origin_begin="14655" data_begin="15871" length="65" time="1"/>
    <range_mapping origin_begin="14720" data_begin="7691" length="47" time="1"/>
    <range_mapping origin_begin="14767" data_begin="16269" length="47" time="1"/>
    <range_mapping origin_begin="14814" data_begin="13019" length="31" time="1"/>
    <range_mapping origin_begin="14845" data_begin="10337" length="65" time="1"/>
    <range_mapping origin_begin="14910" data_begin="15936" length="53" time="1"/>
    <range_mapping origin_begin="14963" data_begin="16341" length="12" time="1"/>
    <range_mapping origin_begin="14975" data_begin="13815" length="63" time="1"/>
    <range_mapping origin_begin="15038" data_begin="11965" length="15" time="1"/>
    <range_mapping origin_begin="15053" data_begin="12486" length="50" time="1"/>
    <range_mapping origin_begin="15103" data_begin="11980" length="65" time="1"/>
    <range_mapping origin_begin="15168" data_begin="2438" length="29" time="1"/>
    <range_mapping origin_begin="15197" data_begin="14508" length="26" time="1"/>
    <range_mapping origin_begin="15223" data_begin="13878" length="8" time="1"/>
    <range_mapping origin_begin="15231" data_begin="10402" length="65" time="1"/>
    <single_mapping origin_block="15296" data_block="11371" time="1"/>
    <range_mapping origin_begin="15297" data_begin="10467" length="65" time="1"/>
    <range_mapping origin_begin="15362" data_begin="13050" length="62" time="1"/>
    <range_mapping origin_begin="15471" data_begin="16541" length="15" time="1"/>
    <range_mapping origin_begin="15486" data_begin="10532" length="65" time="1"/>
    <range_mapping origin_begin="15551" data_begin="11372" length="49" time="1"/>
    <range_mapping origin_begin="15600" data_begin="16353" length="12" time="1"/>
    <range_mapping origin_begin="15612" data_begin="14534" length="66" time="1"/>
    <range_mapping origin_begin="15678" data_begin="15339" length="54" time="1"/>
    <range_mapping origin_begin="15732" data_begin="16556" length="9" time="1"/>
    <range_mapping origin_begin="15741" data_begin="9670" length="65" time="1"/>
    <single_mapping origin_block="15806" data_block="15622" time="1"/>
    <range_mapping origin_begin="15807" data_begin="14600" length="32" time="1"/>
    <range_mapping origin_begin="15839" data_begin="12045" length="19" time="1"/>
    <range_mapping origin_begin="15858" data_begin="10597" length="65" time="1"/>
    <range_mapping origin_begin="15923" data_begin="14632" length="13" time="1"/>
    <range_mapping origin_begin="15936" data_begin="15623" length="45" time="1"/>
    <range_mapping origin_begin="15981" data_begin="13112" length="65" time="1"/>
    <range_mapping origin_begin="16046" data_begin="15668" length="9" time="1"/>
    <range_mapping origin_begin="16055" data_begin="10662" length="56" time="1"/>
    <range_mapping origin_begin="16111" data_begin="9735" length="65" time="1"/>
    <range_mapping origin_begin="16176" data_begin="11421" length="16" time="1"/>
    <range_mapping origin_begin="16192" data_begin="12536" length="45" time="1"/>
    <range_mapping origin_begin="16237" data_begin="9800" length="67" time="1"/>
    <range_mapping origin_begin="16304" data_begin="10718" length="12" time="1"/>
    <range_mapping origin_begin="16316" data_begin="12064" length="49" time="1"/>
    <range_mapping origin_begin="16365" data_begin="14297" length="18" time="1"/>
    <single_mapping origin_block="16383" data_block="17598" time="1"/>
  </device>
</superblock>
END
