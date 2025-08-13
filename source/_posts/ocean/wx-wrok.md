---
title: 企业微信内部应用
date: 2025-07-31 21:32:58
tags:
- "Java"
id: wx-work
no_word_count: true
no_toc: false
categories: 
- "Ocean"
---

## 企业微信内部应用

### 简介

可以创建内部应用，然后使用如下方式生成不同来源的二维码来标记客户。

### 接口清单

首先需要获取企业ID 即 corpid 和 token:

- corpid 在企业详情里面可以获取
- token 在内部应用详情中可以获取

然后需要在配置页的客户部分，打开 API 下拉窗口，然后配置内部应用访问客户的权限。

之后即可按照如下逻辑获取用户的渠道。

[配置客户联系「联系我」方式](https://developer.work.weixin.qq.com/document/path/92228#%E9%85%8D%E7%BD%AE%E5%AE%A2%E6%88%B7%E8%81%94%E7%B3%BB%E3%80%8C%E8%81%94%E7%B3%BB%E6%88%91%E3%80%8D%E6%96%B9%E5%BC%8F)

[获取客户列表](https://developer.work.weixin.qq.com/document/path/92113)

[获取客户详情](https://developer.work.weixin.qq.com/document/path/92114)

[批量获取客户详情](https://developer.work.weixin.qq.com/document/path/92994)

[修改客户备注](https://developer.work.weixin.qq.com/document/path/92115)

如有需求也可以通过企业微信的推送来对接新增的用户，直接进行标注

[回调配置](https://developer.work.weixin.qq.com/document/path/90930)

[回调测试](https://developer.work.weixin.qq.com/devtool/interface/alone?id=14961)

[添加企业客户事件](https://developer.work.weixin.qq.com/document/path/92130#%E6%B7%BB%E5%8A%A0%E4%BC%81%E4%B8%9A%E5%AE%A2%E6%88%B7%E4%BA%8B%E4%BB%B6)

在调试时可以采用如下文件：

```text
### token
@id = aaa
@secret = aaa
GET https://qyapi.weixin.qq.com/cgi-bin/gettoken?corpid={{id}}&corpsecret={{secret}}

> {% client.global.set("token", response.body.access_token); %}

### create_contact
POST https://qyapi.weixin.qq.com/cgi-bin/externalcontact/add_contact_way?access_token={{token}}
Content-Type: application/json

{
    "type": 1,
    "scene": 2,
    "remark": "渠道客户",
    "skip_verify": true,
    "state": "teststate",
    "user": ["xxxx"]
}

### list_contact
POST https://qyapi.weixin.qq.com/cgi-bin/externalcontact/list_contact_way?access_token={{token}}
Content-Type: application/json

{
  "start_time":1622476800,
  "limit":1000
}

### get_contact_config
POST https://qyapi.weixin.qq.com/cgi-bin/externalcontact/get_contact_way?access_token={{token}}
Content-Type: application/json

{
  "config_id":"42b34949e138eb6e027c123cba77fad7"
}

### get_customers
GET https://qyapi.weixin.qq.com/cgi-bin/externalcontact/list?access_token={{token}}&userid={{user_id}}
Content-Type: application/json

### get_customer_details
POST https://qyapi.weixin.qq.com/cgi-bin/externalcontact/batch/get_by_user?access_token={{token}}
Content-Type: application/json

{
  "userid_list": [
    "zhangsan",
    "lisi"
  ],
  "limit": 100
}
```

```text
### get_contact_list
POST https://qyapi.weixin.qq.com/cgi-bin/externalcontact/list_contact_way?access_token={{token}}
Content-Type: application/json

{}

### delete_contact
POST https://qyapi.weixin.qq.com/cgi-bin/externalcontact/del_contact_way?access_token={{token}}
Content-Type: application/json

{
  "config_id": "92fef8ac665d969c40d078ee38b49492"
}

### update_external_contact_info
POST https://qyapi.weixin.qq.com/cgi-bin/externalcontact/remark?access_token={{token}}
Content-Type: application/json

{
  "userid": "xxx",
  "external_userid": "xxx",
  "remark": "xxx-xxx"
}
```

### 回调代码

编辑 gradle 配置：

```groovy
dependencies {
    implementation 'org.springframework.boot:spring-boot-starter-web'
    implementation 'org.springframework.boot:spring-boot-starter-web-services'
    testImplementation 'io.projectreactor:reactor-test'
    compileOnly 'org.projectlombok:lombok'
    developmentOnly 'org.springframework.boot:spring-boot-devtools'
    annotationProcessor 'org.springframework.boot:spring-boot-configuration-processor'
    annotationProcessor 'org.projectlombok:lombok'
    testImplementation 'org.springframework.boot:spring-boot-starter-test'
    testRuntimeOnly 'org.junit.platform:junit-platform-launcher'
}
```

编写 `AesException.java` 文件

```java
import lombok.Getter;

@Getter
public class AesException extends Exception {

    public final static int ValidateSignatureError = -40001;
    public final static int ParseXmlError = -40002;
    public final static int ComputeSignatureError = -40003;
    public final static int IllegalAesKey = -40004;
    public final static int ValidateCorpidError = -40005;
    public final static int EncryptAESError = -40006;
    public final static int DecryptAESError = -40007;
    public final static int IllegalBuffer = -40008;
    public final static int EncodeBase64Error = -40009;
    public final static int DecodeBase64Error = -40010;
    public final static int GenReturnXmlError = -40011;

    private final int code;

    private static String getMessage(int code) {
        return switch (code) {
            case ValidateSignatureError -> "签名验证错误";
            case ParseXmlError -> "xml解析失败";
            case ComputeSignatureError -> "sha加密生成签名失败";
            case IllegalAesKey -> "SymmetricKey非法";
            case ValidateCorpidError -> "corpid校验失败";
            case EncryptAESError -> "aes加密失败";
            case DecryptAESError -> "aes解密失败";
            case IllegalBuffer -> "解密后得到的buffer非法";
            case EncodeBase64Error -> "base64加密错误";
            case DecodeBase64Error -> "base64解密错误";
            case GenReturnXmlError -> "xml生成失败";
            default -> null;
        };
    }

    AesException(int code) {
        super(getMessage(code));
        this.code = code;
    }
}
```

编写 `ByteGroup.java` 文件

```java
import java.util.ArrayList;

public class ByteGroup {

	ArrayList<Byte> byteContainer = new ArrayList<>();

	public byte[] toBytes() {
		byte[] bytes = new byte[byteContainer.size()];
		for (int i = 0; i < byteContainer.size(); i++) {
			bytes[i] = byteContainer.get(i);
		}
		return bytes;
	}

	public void addBytes(byte[] bytes) {
		for (byte b : bytes) {
			byteContainer.add(b);
		}
	}

	public int size() {
		return byteContainer.size();
	}
}
```

编写 `PKCS7Encoder.java` 文件

```java
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;

/**
 * 提供基于PKCS7算法的加解密接口.
 */
public class PKCS7Encoder {

	private static final Charset CHARSET = StandardCharsets.UTF_8;
	private static final int BLOCK_SIZE = 32;

	/**
	 * 获得对明文进行补位填充的字节.
	 * 
	 * @param count 需要进行填充补位操作的明文字节个数
	 * @return 补齐用的字节数组
	 */
	public static byte[] encode(int count) {
		// 计算需要填充的位数
		int amountToPad = BLOCK_SIZE - (count % BLOCK_SIZE);
        // 获得补位所用的字符
		char padChr = chr(amountToPad);
        return String.valueOf(padChr).repeat(amountToPad).getBytes(CHARSET);
	}

	/**
	 * 删除解密后明文的补位字符
	 * 
	 * @param decrypted 解密后的明文
	 * @return 删除补位字符后的明文
	 */
	public static byte[] decode(byte[] decrypted) {
		int pad = (int) decrypted[decrypted.length - 1];
		if (pad < 1 || pad > 32) {
			pad = 0;
		}
		return Arrays.copyOfRange(decrypted, 0, decrypted.length - pad);
	}

	/**
	 * 将数字转化成ASCII码对应的字符，用于对明文进行补码
	 * 
	 * @param a 需要转化的数字
	 * @return 转化得到的字符
	 */
	public static char chr(int a) {
		byte target = (byte) (a & 0xFF);
		return (char) target;
	}

}
```

编写 `SHA1.java` 文件：

```java
import java.security.MessageDigest;
import java.util.Arrays;

/**
 * SHA1 class
 * 计算消息签名接口.
 */
public class SHA1 {

	/**
	 * 用SHA1算法生成安全签名
	 * @param token 票据
	 * @param timestamp 时间戳
	 * @param nonce 随机字符串
	 * @param encrypt 密文
	 * @return 安全签名
     */
	public static String getSHA1(String token, String timestamp, String nonce, String encrypt) throws AesException
			  {
		try {
			String[] array = new String[] { token, timestamp, nonce, encrypt };
			StringBuilder sb = new StringBuilder();
			// 字符串排序
			Arrays.sort(array);
			for (int i = 0; i < 4; i++) {
				sb.append(array[i]);
			}
			String str = sb.toString();
			// SHA1签名生成
			MessageDigest md = MessageDigest.getInstance("SHA-1");
			md.update(str.getBytes());
			byte[] digest = md.digest();

			StringBuilder hexStr = new StringBuilder();
			String shaHex;
            for (byte b : digest) {
                shaHex = Integer.toHexString(b & 0xFF);
                if (shaHex.length() < 2) {
					hexStr.append(0);
                }
				hexStr.append(shaHex);
            }
			return hexStr.toString();
		} catch (Exception e) {
			e.printStackTrace();
			throw new AesException(AesException.ComputeSignatureError);
		}
	}
}
```

编写 `XMLParse.java` 文件：

```java
import org.w3c.dom.Document;
import org.w3c.dom.Element;
import org.w3c.dom.NodeList;
import org.xml.sax.InputSource;

import javax.xml.parsers.DocumentBuilder;
import javax.xml.parsers.DocumentBuilderFactory;
import java.io.StringReader;

/**
 * XMLParse class
 * 提供提取消息格式中的密文及生成回复消息格式的接口.
 */
public class XMLParse {

	/**
	 * 提取出xml数据包中的加密消息
	 * @param xmltext 待提取的xml字符串
	 * @return 提取出的加密消息字符串
     */
	public static Object[] extract(String xmltext) throws AesException     {
		Object[] result = new Object[3];
		try {
			DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
			
			String FEATURE;
			FEATURE = "http://apache.org/xml/features/disallow-doctype-decl";
			dbf.setFeature(FEATURE, true);

			FEATURE = "http://xml.org/sax/features/external-general-entities";
			dbf.setFeature(FEATURE, false);

			FEATURE = "http://xml.org/sax/features/external-parameter-entities";
			dbf.setFeature(FEATURE, false);

			FEATURE = "http://apache.org/xml/features/nonvalidating/load-external-dtd";
			dbf.setFeature(FEATURE, false);

			dbf.setXIncludeAware(false);
			dbf.setExpandEntityReferences(false);

			DocumentBuilder db = dbf.newDocumentBuilder();
			StringReader sr = new StringReader(xmltext);
			InputSource is = new InputSource(sr);
			Document document = db.parse(is);

			Element root = document.getDocumentElement();
			NodeList nodelist1 = root.getElementsByTagName("Encrypt");
			result[0] = 0;
			result[1] = nodelist1.item(0).getTextContent();
			return result;
		} catch (Exception e) {
			e.printStackTrace();
			throw new AesException(AesException.ParseXmlError);
		}
	}

	/**
	 * 生成xml消息
	 * @param encrypt 加密后的消息密文
	 * @param signature 安全签名
	 * @param timestamp 时间戳
	 * @param nonce 随机字符串
	 * @return 生成的xml字符串
	 */
	public static String generate(String encrypt, String signature, String timestamp, String nonce) {

		String format = """
                <xml>
                <Encrypt><![CDATA[%1$s]]></Encrypt>
                <MsgSignature><![CDATA[%2$s]]></MsgSignature>
                <TimeStamp>%3$s</TimeStamp>
                <Nonce><![CDATA[%4$s]]></Nonce>
                </xml>""";
		return String.format(format, encrypt, signature, timestamp, nonce);

	}
}
```

编写 `WXBizMsgCrypt.java` 文件

```java
import javax.crypto.Cipher;
import javax.crypto.spec.IvParameterSpec;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.Charset;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;
import java.util.Base64;
import java.util.Objects;
import java.util.Random;

public class WXBizMsgCrypt {

	private static final Charset CHARSET = StandardCharsets.UTF_8;
	private final byte[] aesKey;
	private final String token;
	private final String receiveid;

	/**
	 * 构造函数
	 * @param token 企业微信后台，开发者设置的token
	 * @param encodingAesKey 企业微信后台，开发者设置的EncodingAESKey
	 * @param receiveid, 不同场景含义不同，详见文档
	 *
	 * @throws AesException 执行失败，请查看该异常的错误码和具体的错误信息
	 */
	public WXBizMsgCrypt(String token, String encodingAesKey, String receiveid) throws AesException {
		if (encodingAesKey.length() != 43) {
			throw new AesException(AesException.IllegalAesKey);
		}

		this.token = token;
		this.receiveid = receiveid;
		aesKey = Base64.getDecoder().decode(encodingAesKey + "=");
	}

	// 生成4个字节的网络字节序
	byte[] getNetworkBytesOrder(int sourceNumber) {
		byte[] orderBytes = new byte[4];
		orderBytes[3] = (byte) (sourceNumber & 0xFF);
		orderBytes[2] = (byte) (sourceNumber >> 8 & 0xFF);
		orderBytes[1] = (byte) (sourceNumber >> 16 & 0xFF);
		orderBytes[0] = (byte) (sourceNumber >> 24 & 0xFF);
		return orderBytes;
	}

	// 还原4个字节的网络字节序
	int recoverNetworkBytesOrder(byte[] orderBytes) {
		int sourceNumber = 0;
		for (int i = 0; i < 4; i++) {
			sourceNumber <<= 8;
			sourceNumber |= orderBytes[i] & 0xff;
		}
		return sourceNumber;
	}

	// 随机生成16位字符串
	String getRandomStr() {
		String base = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789";
		Random random = new Random();
		StringBuilder sb = new StringBuilder();
		for (int i = 0; i < 16; i++) {
			int number = random.nextInt(base.length());
			sb.append(base.charAt(number));
		}
		return sb.toString();
	}

	/**
	 * 对明文进行加密.
	 *
	 * @param text 需要加密的明文
	 * @return 加密后base64编码的字符串
	 * @throws AesException aes加密失败
	 */
	String encrypt(String randomStr, String text) throws AesException {
		ByteGroup byteCollector = new ByteGroup();
		byte[] randomStrBytes = randomStr.getBytes(CHARSET);
		byte[] textBytes = text.getBytes(CHARSET);
		byte[] networkBytesOrder = getNetworkBytesOrder(textBytes.length);
		byte[] receiveidBytes = receiveid.getBytes(CHARSET);

		// randomStr + networkBytesOrder + text + receiveid
		byteCollector.addBytes(randomStrBytes);
		byteCollector.addBytes(networkBytesOrder);
		byteCollector.addBytes(textBytes);
		byteCollector.addBytes(receiveidBytes);

		// ... + pad: 使用自定义的填充方式对明文进行补位填充
		byte[] padBytes = PKCS7Encoder.encode(byteCollector.size());
		byteCollector.addBytes(padBytes);

		// 获得最终的字节流, 未加密
		byte[] unencrypted = byteCollector.toBytes();

		try {
			// 设置加密模式为AES的CBC模式
			Cipher cipher = Cipher.getInstance("AES/CBC/NoPadding");
			SecretKeySpec keySpec = new SecretKeySpec(aesKey, "AES");
			IvParameterSpec iv = new IvParameterSpec(aesKey, 0, 16);
			cipher.init(Cipher.ENCRYPT_MODE, keySpec, iv);

			// 加密
			byte[] encrypted = cipher.doFinal(unencrypted);

			// 使用BASE64对加密后的字符串进行编码

            return Base64.getEncoder().encodeToString(encrypted);
		} catch (Exception e) {
			e.printStackTrace();
			throw new AesException(AesException.EncryptAESError);
		}
	}

	/**
	 * 对密文进行解密.
	 *
	 * @param text 需要解密的密文
	 * @return 解密得到的明文
	 * @throws AesException aes解密失败
	 */
	String decrypt(String text) throws AesException {
		byte[] original;
		try {
			// 设置解密模式为AES的CBC模式
			Cipher cipher = Cipher.getInstance("AES/CBC/NoPadding");
			SecretKeySpec key_spec = new SecretKeySpec(aesKey, "AES");
			IvParameterSpec iv = new IvParameterSpec(Arrays.copyOfRange(aesKey, 0, 16));
			cipher.init(Cipher.DECRYPT_MODE, key_spec, iv);

			// 使用BASE64对密文进行解码
			byte[] encrypted = Base64.getDecoder().decode(text);

			// 解密
			original = cipher.doFinal(encrypted);
		} catch (Exception e) {
			e.printStackTrace();
			throw new AesException(AesException.DecryptAESError);
		}

		String xmlContent, from_receiveid;
		try {
			// 去除补位字符
			byte[] bytes = PKCS7Encoder.decode(original);

			// 分离16位随机字符串,网络字节序和receiveid
			byte[] networkOrder = Arrays.copyOfRange(bytes, 16, 20);

			int xmlLength = recoverNetworkBytesOrder(networkOrder);

			xmlContent = new String(Arrays.copyOfRange(bytes, 20, 20 + xmlLength), CHARSET);
			from_receiveid = new String(Arrays.copyOfRange(bytes, 20 + xmlLength, bytes.length),
					CHARSET);
		} catch (Exception e) {
			e.printStackTrace();
			throw new AesException(AesException.IllegalBuffer);
		}

		// receiveid不相同的情况
		if (!from_receiveid.equals(receiveid)) {
			throw new AesException(AesException.ValidateCorpidError);
		}
		return xmlContent;

	}

	/**
	 * 将企业微信回复用户的消息加密打包.
	 * <ol>
	 * 	<li>对要发送的消息进行AES-CBC加密</li>
	 * 	<li>生成安全签名</li>
	 * 	<li>将消息密文和安全签名打包成xml格式</li>
	 * </ol>
	 *
	 * @param replyMsg 企业微信待回复用户的消息，xml格式的字符串
	 * @param timeStamp 时间戳，可以自己生成，也可以用URL参数的timestamp
	 * @param nonce 随机串，可以自己生成，也可以用URL参数的nonce
	 *
	 * @return 加密后的可以直接回复用户的密文，包括msg_signature, timestamp, nonce, encrypt的xml格式的字符串
	 * @throws AesException 执行失败，请查看该异常的错误码和具体的错误信息
	 */
	public String EncryptMsg(String replyMsg, String timeStamp, String nonce) throws AesException {
		// 加密
		String encrypt = encrypt(getRandomStr(), replyMsg);
		// 生成安全签名
		if (Objects.equals(timeStamp, "")) {
			timeStamp = Long.toString(System.currentTimeMillis());
		}

		String signature = SHA1.getSHA1(token, timeStamp, nonce, encrypt);

		// System.out.println("发送给平台的签名是: " + signature[1].toString());
		// 生成发送的xml
        return XMLParse.generate(encrypt, signature, timeStamp, nonce);
	}

	/**
	 * 检验消息的真实性，并且获取解密后的明文.
	 * <ol>
	 * 	<li>利用收到的密文生成安全签名，进行签名验证</li>
	 * 	<li>若验证通过，则提取xml中的加密消息</li>
	 * 	<li>对消息进行解密</li>
	 * </ol>
	 *
	 * @param msgSignature 签名串，对应URL参数的msg_signature
	 * @param timeStamp 时间戳，对应URL参数的timestamp
	 * @param nonce 随机串，对应URL参数的nonce
	 * @param postData 密文，对应POST请求的数据
	 *
	 * @return 解密后的原文
	 * @throws AesException 执行失败，请查看该异常的错误码和具体的错误信息
	 */
	public String DecryptMsg(String msgSignature, String timeStamp, String nonce, String postData)
			throws AesException {

		// 密钥，公众账号的app secret
		// 提取密文
		Object[] encrypt = XMLParse.extract(postData);

		// 验证安全签名
		String signature = SHA1.getSHA1(token, timeStamp, nonce, encrypt[1].toString());

		// 和URL中的签名比较是否相等
		if (!signature.equals(msgSignature)) {
			throw new AesException(AesException.ValidateSignatureError);
		}

		// 解密
        return decrypt(encrypt[1].toString());
	}

	/**
	 * 验证URL
	 * @param msgSignature 签名串，对应URL参数的msg_signature
	 * @param timeStamp 时间戳，对应URL参数的timestamp
	 * @param nonce 随机串，对应URL参数的nonce
	 * @param echoStr 随机串，对应URL参数的echostr
	 *
	 * @return 解密之后的echostr
	 * @throws AesException 执行失败，请查看该异常的错误码和具体的错误信息
	 */
	public String VerifyURL(String msgSignature, String timeStamp, String nonce, String echoStr)
			throws AesException {
		String signature = SHA1.getSHA1(token, timeStamp, nonce, echoStr);

		if (!signature.equals(msgSignature)) {
			throw new AesException(AesException.ValidateSignatureError);
		}

        return decrypt(echoStr);
	}

}
```

编辑 `WechatCallbackRequest.java` 文件

```java
import jakarta.xml.bind.annotation.XmlAccessType;
import jakarta.xml.bind.annotation.XmlAccessorType;
import jakarta.xml.bind.annotation.XmlElement;
import jakarta.xml.bind.annotation.XmlRootElement;
import lombok.Data;

@Data
@XmlRootElement(name = "xml")
@XmlAccessorType(XmlAccessType.FIELD)
public class WechatCallbackRequest {

    @XmlElement(name = "ToUserName")
    private String toUserName;

    @XmlElement(name = "FromUserName")
    private String fromUserName;

    @XmlElement(name = "CreateTime")
    private Long createTime;

    @XmlElement(name = "MsgType")
    private String msgType;

    @XmlElement(name = "Event")
    private String event;

    @XmlElement(name = "ChangeType")
    private String changeType;

    @XmlElement(name = "UserID")
    private String userId;

    @XmlElement(name = "ExternalUserID")
    private String externalUserId;

    @XmlElement(name = "State")
    private String state;

    @XmlElement(name = "WelcomeCode")
    private String welcomeCode;

    // 加密相关字段
    @XmlElement(name = "Encrypt")
    private String encrypt;

}
```

编辑 `WxConfig.java` 文件：

```java
import lombok.Data;
import org.springframework.boot.context.properties.ConfigurationProperties;
import org.springframework.stereotype.Component;

@Data
@Component
@ConfigurationProperties(prefix = "wx")
public class WxConfig {

    private String token = "QDG6eK";
    private String cropId = "wx5823bf96d3bd56c7";
    private String aesKey = "jWmYm7qr5nMoAUwZRjGtBxmz3KA1tkAj3ykkR6q2B2C";

}
```

编辑 `WxService.java` 文件：

```java
import jakarta.xml.bind.JAXBContext;
import jakarta.xml.bind.Unmarshaller;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Async;
import org.springframework.stereotype.Service;

import java.io.StringReader;
import java.util.concurrent.CompletableFuture;

@Slf4j
@Service
public class WxService {

    private final WXBizMsgCrypt wxcpt;

    public WxService(WxConfig wxConfig) throws AesException {
        wxcpt = new WXBizMsgCrypt(wxConfig.getToken(), wxConfig.getAesKey(), wxConfig.getCropId());
    }

    @Async
    public CompletableFuture<String> verifyUrl(String msgSignature, String timestamp, String nonce, String echoStr) throws AesException {
        return CompletableFuture.completedFuture(wxcpt.VerifyURL(msgSignature, timestamp, nonce, echoStr));
    }

    @Async
    public CompletableFuture<String> decodeData(String msgSignature, String timestamp, String nonce, String encryptMsg) throws Exception {
        String sMsg = wxcpt.DecryptMsg(msgSignature, timestamp, nonce, encryptMsg);
        JAXBContext jaxbContext = JAXBContext.newInstance(WechatCallbackRequest.class);
        Unmarshaller unmarshaller = jaxbContext.createUnmarshaller();
        WechatCallbackRequest request = (WechatCallbackRequest) unmarshaller.unmarshal(new StringReader(sMsg));
        log.error(String.valueOf(request));
        return CompletableFuture.completedFuture("success");
    }

}
```

编辑 `WxCallbackController.java` 文件：

```java
import jakarta.annotation.Resource;
import lombok.extern.slf4j.Slf4j;
import org.springframework.web.bind.annotation.*;

import java.util.concurrent.CompletableFuture;

@Slf4j
@RestController
@RequestMapping("/wechat/callback")
public class WxCallbackController {

    @Resource
    private WxService wxService;

    @GetMapping
    public CompletableFuture<String> verifyUrl(
            @RequestParam("msg_signature") String msgSignature,
            @RequestParam("timestamp") String timestamp,
            @RequestParam("nonce") String nonce,
            @RequestParam("echostr") String echostr) throws AesException {
        return wxService.verifyUrl(msgSignature, timestamp, nonce, echostr);
    }

    @PostMapping
    public CompletableFuture<String> receiveCallback(@RequestParam("msg_signature") String msgSignature,
                                  @RequestParam("timestamp") String timestamp,
                                  @RequestParam("nonce") String nonce,
                                  @RequestBody String encryptMsg) throws Exception {
        return wxService.decodeData(msgSignature, timestamp, nonce, encryptMsg);
    }

}
```

编辑 `Application.java` 文件：

```java
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.scheduling.annotation.EnableAsync;

@SpringBootApplication
@EnableAsync
public class Application {

    public static void main(String[] args) {
        SpringApplication.run(Application.class, args);
    }

}
```

编辑 `appilcation.yaml` 配置文件：

```yaml
spring:
  application:
    name: wxtest
  threads:
    virtual:
      enabled: true
```

运行之后可以使用 `test.http` 文件进行测试：

```text
### Test verify
GET http://localhost:8080/wechat/callback?msg_signature=5c45ff5e21c57e6ad56bac8758b79b1d9ac89fd3&timestamp=1409659589&nonce=263014780&echostr=P9nAzCzyDtyTWESHep1vC5X9xho/qYX3Zpb4yKa9SKld1DsH3Iyt3tP3zNdtp+4RPcs8TgAE7OaBO+FZXvnaqQ==
Content-Type: application/json

### Test decode
POST http://localhost:8080/wechat/callback?msg_signature=477715d11cdb4164915debcba66cb864d751f3e6&timestamp=1409659813&nonce=1372623149
Content-Type: application/xml

<xml>
    <ToUserName><![CDATA[wx5823bf96d3bd56c7]]></ToUserName>
    <Encrypt><![CDATA[RypEvHKD8QQKFhvQ6QleEB4J58tiPdvo+rtK1I9qca6aM/wvqnLSV5zEPeusUiX5L5X/0lWfrf0QADHHhGd3QczcdCUpj911L3vg3W/sYYvuJTs3TUUkSUXxaccAS0qhxchrRYt66wiSpGLYL42aM6A8dTT+6k4aSknmPj48kzJs8qLjvd4Xgpue06DOdnLxAUHzM6+kDZ+HMZfJYuR+LtwGc2hgf5gsijff0ekUNXZiqATP7PF5mZxZ3Izoun1s4zG4LUMnvw2r+KqCKIw+3IQH03v+BCA9nMELNqbSf6tiWSrXJB3LAVGUcallcrw8V2t9EL4EhzJWrQUax5wLVMNS0+rUPA3k22Ncx4XXZS9o0MBH27Bo6BpNelZpS+/uh9KsNlY6bHCmJU9p8g7m3fVKn28H3KDYA5Pl/T8Z1ptDAVe0lXdQ2YoyyH2uyPIGHBZZIs2pDBS8R07+qN+E7Q==]]></Encrypt>
    <AgentID><![CDATA[218]]></AgentID>
</xml>
```