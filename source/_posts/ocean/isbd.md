---
title: Iridium Short Burst Data
date: 2024-04-01 21:32:58
tags:
- "Python"
id: isbd
no_word_count: true
no_toc: false
categories: Ocean
---

## Iridium Short Burst Data

### 简介

Iridium Short Burst Data 是铱星的一种短报文，报文可以通过 DirectIP 方式或邮件的方式推送到客户侧。按照本文进行编码即可获得一个测试服务器。

### 使用方式

使用如下命令安装依赖包：

```bash
sudo yum install python3-devel mysql-devel pkgconfig
pip3 install mysqlclient thread
```

然后编写如下 `isbd.py` 数据解析文件：

```python
#!/usr/bin/python
help = '''isbd.py - Chris X Edwards - 2016-11-03
ISBD Message Handling Library 

The purpose of this module is to handle the necessary data management issues
with messages received from the Iridium Short Burst Data system.
https://en.wikipedia.org/wiki/Iridium_Communications#Short_burst_data
This involves unpacking the received messages and providing access to member
components. It also can provide diverse services for how to archive, display,
or process the received data including saving to a sensible filesystem
structure and inserting into databases.

See extensive notes at http://xed.ch/project/isbd for a complete analysis of
how ISBD messages are composed.

License: LGPL V.3 - https://www.gnu.org/licenses/lgpl-3.0.txt
'''


def joinStr(data: list):
    result = ""
    for ele in range(len(data)):
        result = result + data[ele].decode()
    return result


class Isbdmsg:
    '''The Isbdmsg class represents the data of the received message. Class
    methods allow the original data to be unpacked, queried, checked, output,
    archived, and anything else that may relate to the ISBD message
    handling.'''

    def __init__(self, data=None):
        self.load(data)

    def load(self, data):
        '''A separate function so that users can create empty objects and load
        them (or reload them) with different data by calling only this
        function. With an argument of 'None' this should also clear the data
        from a full object.'''
        self.entire_isbd_msg = data
        self.unpack()

    def unpack(self):
        '''Extract all possible ISBD message header data fields from the binary
        ISBD message blob received. If the data blob is not present (in
        `self.entire_isbd_msg`), then all of the fields will get a value of
        'None'.'''
        import struct
        import binascii
        if self.entire_isbd_msg:
            l = len(self.entire_isbd_msg)  # Or `self.total_msg_len` might work. Should check that.
            packformat = '>cHcHIccccccccccccccccHHIcHccHcHIcH' + 'c' * (l - 51)
            m = list(struct.unpack(packformat, self.entire_isbd_msg))  # m is message component list.
            for n in [0, 2, 20, 24, 32]:  # For these fields...
                m[n] = binascii.hexlify(m[n])  # ...fix binary coded numbers to be proper numbers.
            for n in [26, 27, 29]:
                m[n] = ord(m[n])  # Byte to int values for location orient and degrees
        else:
            m = [None for N in range(35)]  # At least 35 components.
        self.msg_protocol_ver = m[0]  # Should always equal 1.
        self.total_msg_len = m[1]  # Number of bytes sent by ISBD.
        self.mo_header_iei = m[2]  # Should always equal 1.
        self.mo_header_len = m[3]  # Should always equal 28.
        self.cdr_ref = m[4]  # Call Detail Record Reference. An automatic ID number.
        if m[5]:  # Only if the data is ready
            self.imei = joinStr(m[5:20])  # IMEI Unit Identification.
        else:
            self.imei = None  # The whole field is set to None.
        self.status = m[20]  # Session status - 0=success; 1&2 also mostly ok.; 10,12-15=problem
        self.momsn = m[21]  # Mobile Originated Message Sequence Number.
        self.mtmsn = m[22]  # Mobile Terminated Message Sequence Number. Should equal 0.
        self.msg_timestamp = m[23]  # Time Iridium sees msg (not unit generated or arrival). Seconds since epoch.
        self.payload_header_iei = m[24]  # Should always equal 3.
        self.payload_header_len = m[25]  # Should always be 11.
        self.loc_orient = m[26]  # Location orientation code (0=N,E; 1=N,W; 2=S,E; 3=S,W).
        self.loc_lat_deg = m[27]  # Latitude - degree part.
        self.loc_lat_min = m[28]  # Latitude - minute part.
        self.loc_lon_deg = m[29]  # Longitude - degree part.
        self.loc_lon_min = m[30]  # Longitude - minute part.
        self.cep_radius = m[31]  # Circular Error Probable (CEP) Radius.
        self.payload_iei = m[32]  # Start of Payload IEI type. Should always equal 2.
        self.payload_len = m[33]  # Length of this payload
        if m[34]:
            self.payload = joinStr(m[34:])  # The actual message sent from the unit, bit for bit.
            self.payload_hex = binascii.hexlify(self.payload.encode())  # Printable hex _string_ of payload.
        else:
            self.payload = None
            self.payload_hex = None
        return self  # Allows `M= Isbdmsg().unpack()`

    def pack(self):
        '''In theory, this should be similar to unpack using the struct.pack() function.
        In practice, each field will have to be checked to make sure it is ready and
        many fields will have to be converted to the proper type. This would be useful
        for synthesizing new binary messages suitable for testing as well as for editing
        exisiting ones.'''
        pass  # TODO

    def __repr__(self):
        o = ['%s: %s' % N for N in self.parts_for_output()]
        # Just draws an asciiart box; more simply: '\n'.join(o)
        return '/%s\n| %s\n\%s' % ('-' * 54, '\n| '.join(o), '-' * 54)

    def html(self):
        '''HTMLized string representation of message object.'''
        o = ['<tr><td>%s</td><td>%s</td></tr>' % N for N in self.parts_for_output()]
        return '<table class="isbdmsg">\n%s\n</table>' % '\n'.join(o)

    def parts_for_output(self):
        '''Returns a list of (label,value) tuples of suitable output components.
        Applicable to various output modes.'''
        o = list()
        o.append(("IMEI", self.imei))
        o.append(("Message protocol version", self.msg_protocol_ver))
        o.append(("Total message length", self.total_msg_len))
        o.append(("MO header IEI", self.mo_header_iei))
        o.append(("MO header length", self.mo_header_len))
        o.append(("Call Detail Record Reference", self.cdr_ref))
        o.append(("Session status", self.status))
        o.append(("MO MSN", self.momsn))
        o.append(("MT MSN", self.mtmsn))
        o.append(("Message timestamp", self.msg_timestamp))
        o.append(("Payload header IEI", self.payload_header_iei))
        o.append(("Payload header len", self.payload_header_len))
        o.append(("Location orientation code", self.loc_orient))
        o.append(("Location latitude (deg)", self.loc_lat_deg))
        o.append(("Location latitude (min)", self.loc_lat_min))
        o.append(("Location longitude (deg)", self.loc_lon_deg))
        o.append(("Location longitude (min)", self.loc_lon_min))
        o.append(("CEP radius", self.cep_radius))
        o.append(("Payload IEI", self.payload_iei))
        o.append(("Payload length", self.payload_len))
        o.append(("Payload (hex)", self.payload_hex))
        return o

    def errors_check_msg(self):
        '''Checks issues with the entire message itself.
        Returns errors found. Or 'None', i.e. no errors, if good.'''
        l = len(self.entire_isbd_msg)
        if not l:
            return "Message not present!"
        elif l < 48 or l > 400:
            return "Unknown message of length %d" % l
        return None

    def errors_check_parts(self):
        '''Some things should reliably be constant values in all messages. It
        may not be catastrophic if not, but it might be worth a log entry.
        Returns errors found. Or 'None', i.e. no errors, if good.'''
        w = list()  # Cumulative list of warnings.
        if not self.msg_protocol_ver == '01':
            w.append('ISBD Message Protocol Version should be 1, value is: %s' % self.msg_protocol_ver)
        if not self.mo_header_iei == '01':
            w.append(
                'ISBD Message Originate Information Element Identifier should be 1, value is: %s' % self.mo_header_iei)
        if not self.mo_header_len == 28:
            w.append('ISBD Message Originate Header Length should be 28, value is: %s' % self.mo_header_len)
        if not self.mtmsn == 0:
            w.append(
                'ISBD Mobile Terminated Message Seqence Number is not 0 (should only be MO), value is: %s' % self.mtmsn)
        if not self.payload_header_iei == '03':
            w.append('ISBD Payload Header Code is not 3, value is: %s' % self.payload_header_iei)
        if not self.payload_iei == '02':
            w.append('ISBD Message Payload Information Element Identifier should be 2, value is: %s' % self.payload_iei)
        if len(w):
            return '\n'.join(w)
        else:
            return None

    def log_entry(self):
        '''Return a string suitable for putting in a log file for a server.
        Maybe let the server add the timestamp.'''
        # Since it's parsed, print a nice summary of the transaction for the log.
        o = str()
        # o+="RECV:"                    # SUPPLIED BY SERVER!!
        # o+="%s/%d,"       %a          # Remote IP address and port SUPPLIED BY SERVER!!
        o += "n=%s," % self.total_msg_len  # SBD message length
        o += "I=%s," % self.imei  # International Mobile Equipment ID Number (IMEI)
        o += "S=%s," % self.status  # Session status code
        o += "T=%s," % self.timestamp_fmt('log')  # Timestamp encoded in message (not server arrival)
        o += "L=%s," % self.location_fmt('log')  # Location latitude and longitude
        o += "D=%s," % self.cdr_ref  # Call Detail Record Reference ID Number
        o += "M=%s," % self.momsn  # MO Message Sequence Number
        o += "C=%s" % self.cep_radius  # CEP radius
        return o

    def execute_mysql(self, con, sql):
        '''Connect to a MySQL/MariaDB database using the supplied connection parameters
        and execute the SQL. `con` should be a dict similar to this:
            {'host':'sql.xed.ch', 'user':'xedtester', 'passwd':pw, 'db':'isbd_msg'} '''
        import MySQLdb
        connection = MySQLdb.connect(**con)
        cursor = connection.cursor()
        cursor.execute(*sql)
        connection.commit()
        cursor.close()
        connection.close()

    def insert_in_mysql(self, con):
        '''Do an SQL "INSERT" to add this ISBD message as a record.'''
        sql = 'INSERT INTO sensible_single_table VALUES ("field1_val","field2_val","field3_val","fieldN_val");'
        self.execute_mysql(con, sql)

    def insert_in_pgsql(self, con):
        '''Connect to a PostgreSQL database using the supplied connection
        parameters and "INSERT" this message as a record.'''
        pass  # TODO

    def read_sbd_file(self, filename):
        '''Load data a message blob from a file system file and unpack so that
        the object is ready to use with the files contents. This could be useful
        to load archived received message files for testing or later analysis.'''
        try:
            f = open(filename, 'rb')
            self.entire_isbd_msg = f.read()
            f.close()
        except IOError:
            print("IOError reading file %s." % filename)
        self.unpack()  # It seems reasonable to always assume this is desired.
        return self  # Allows `M= Isbdmsg().read_sbd_file(file)`

    def write_sbd_file(self, filename):
        '''Write this binary message blob to a file. This could be useful for
        writing message received by a socket server or some other kind of
        acquisition mechanism or it could be used to create message files of
        synthesized data.'''
        import os
        try:
            d = os.path.dirname(filename)
            if not os.path.exists(d):
                os.makedirs(d)
            f = open(filename, 'wb')
            f.write(self.entire_isbd_msg)
            f.close()
        except IOError:
            print("IOError writing file %s." % filename)

    def dated_filename(self, basedir, bonus=''):
        '''This will create a filename sensible for storing received messages.
        It will require a top level base directory, something like
        "/home/isbd/data/received".
        It will figure out a date-based subdirectory from the message metadata,
        not actual arrival time, allowing same day messages to be grouped properly.
        "/home/isbd/data/received/20161106".
        Note this is just a name; the directory is checked for existence on
        write_sbd_file(). The file name will start with the IMEI and full date.
        An optional bonus string (not int) can be supplied to further identify
        the file; this is ideal for sending `'-%06d'%mno` where mno is an
        integer of the server's message number. Example call and returned value.
        M.dated_filename('/home/isbd/newmessages','-%06d'%369)
        /home/isbd/newmessages/20161105/20161105180202-300234063250980-000371.sbd
        '''
        subdir = self.timestamp_fmt('justdate')
        if not subdir:
            subdir = "unknown"
        # There is some uncertaintly about whether to put timestamp or imei first.
        return '%s/%s/%s-%s%s.sbd' % (basedir, subdir, self.timestamp_fmt(), self.imei, bonus)

    def timestamp_fmt(self, style='log'):
        '''Useful for using the time stamp found in `self.msg_timestamp` in a more
        practical way. The format of msg_timestamp is in seconds since the Unix epoch.
        This function returns a string that is more human readable.'''
        t = self.msg_timestamp
        if not t: return None
        import datetime
        if style == 'log':
            return datetime.datetime.fromtimestamp(t).strftime("%Y%m%d%H%M%S")
        elif style == 'justdate':
            return datetime.datetime.fromtimestamp(t).strftime("%Y%m%d")
        elif style == 'iso8601':
            return datetime.datetime.fromtimestamp(t).strftime("%Y-%m-%dT%H:%M:%SZ")
        elif style == 'mysql':
            return datetime.datetime.fromtimestamp(t).strftime("%Y-%m-%d %H:%M:%S")
        return None

    def location_fmt(self, style="human"):
        '''Return a formatted string of the message location.
        Useful for using geographic coordinates in different applications.
        Styles can cover all different types of fashionable lat/long formats.
        See https://en.wikipedia.org/wiki/ISO_6709 for example.
        This function returns a string that is more human readable and/or more
        useful with other software.'''
        # orient,ladeg,lamin,lodeg,lomin
        o = self.loc_orient
        ladeg = self.loc_lat_deg
        lamin = self.loc_lat_min * .001
        lodeg = self.loc_lon_deg
        lomin = self.loc_lon_min * .001
        ladir, lodir = "+-", "+-"
        ladir = ladir[o & 2 and 1]
        lodir = lodir[o & 1]
        la = ladir + '%.6f' % (ladeg + lamin / 60.0)
        lo = lodir + '%.6f' % (lodeg + lomin / 60.0)
        if style == 'svg':
            return '<circle r="1px"  cx="%s" cy="%s" />' % (lo, la)
        elif style == 'lat':
            return float(la)
        elif style == 'lon':
            return float(lo)
        elif style == 'iso6709':
            pass
        elif style == 'google':  # http://maps.google.com/maps?q=-37.771008,-122.412175
            pass
        elif style == 'log':  # E.g. +6d46.945'+138d15.134'
            return "%s%sd%.3f'%s%sd%.3f'" % (ladir, ladeg, lamin, lodir, lodeg, lomin)
        elif style == 'human':
            return 'lat: %s, lon: %s' % (lo, la)

    def send_as_socket_client(self, con):
        '''Useful for testing servers. A testing program could be written that
        goes through a set of archived files and simulates the Iridium network
        using them as sample messages. Or a program could be written that
        creates synthetic test messages and sends them at programmed intervals.
        Needs connection information taking the form of a tuple of host and port.
        con= ('isbdserver.example.edu',10800)
        AF_INET is Address Family IPv4
        SOCK_STREAM is TCP protocol (SOCK_DGRAM for UDP)
        '''
        import socket
        try:
            s = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            s.connect(con)
            s.send(self.entire_isbd_msg)
            s.close()
        except socket.error as msg:
            return 'ERROR: ISBD socket client failed! %s (error #%s)' % (msg[1], str(msg[0]))
        return True


def n(s):
    '''numberify - Convert numeric string values to actual integers if possible
    or floats if not or return 0 if seemingly not numeric. This is handy for sending
    strings to databases and possibly other uses.
    FYI - Ok for strings like '-0E0', but breaks with strings like 'nan'.'''
    try:
        f = float(s)
    except ValueError:
        return 0
    if int(f) == f: return int(f)
    return float(f)


def module_unit_test():
    '''This module is designed to be imported by other programs, for example an
    ISBD message server which receives data from the internet. By itself, its
    only functionality is to perform some self tests. Everything in the MAIN
    section is a test.'''
    # These sample messages were created by doing something like this in a Python interpreter...
    # x=open('example.sbd','rb').read()
    # ...and then cutting and pasting the value of the variable (not printed, just x<enter>).
    sample_msg1 = '\x01\x00E\x01\x00\x1c\x9dL\xce{300230000000000\x00\x15\x9d\x00\x00X\x1b\x19\xe0\x03\x00\x0b\x00\x06\x8c\xda\x8av\xfe\x00\x00\x00\x08\x02\x00\x15\x00!a\xac\x0c\x85\xb2\x8f\xf4\x9f\x08k\x0f\xf0\x00\x00\x00\x00\x07\xff|'
    sample_msg2 = '\x01\x00E\x01\x00\x1c\x9d\x81\x98\x1f300230000000001\x00\x15\xf0\x00\x00X\x1d\xe6N\x03\x00\x0b\x00\x06\xb7a\x8a;\x1e\x00\x00\x00\x04\x02\x00\x15\x00!b\xb8\x0cO\xb1\x0f\xf3\x9e\x04j\x02\x07bV\xc2A\xea\x95|'
    M = Isbdmsg(sample_msg1)
    print("* Message instantiation successful.")
    M.unpack()
    print("* Message unpacking successful.")
    if not M.errors_check_msg():
        print("* Entire message error checks successful.")
    if not M.errors_check_parts():
        print("* Message parts error checks successful.")
    print(M.location_fmt())
    print(M.timestamp_fmt())
    print("Entire message:\n%s" % M)
    N = Isbdmsg()  # Try spawning an empty one.
    print("* Empty message spawn successful.")
    print("* Empty message value should be 'None', is: %s" % str(N.mtmsn))
    N.entire_isbd_msg = sample_msg2
    print("* Loaded sample message 2 into empty message.")
    N.unpack()
    print("* Unpacked message 2 into empty message.")
    print("Entire message:\n%s" % N)
    print("Entire message in HTML table:\n%s" % N.html())
    print("* Sample log entry for message2:\n%s" % N.log_entry())
    O = Isbdmsg()
    O.read_sbd_file('/home/isbd/data/received/20161105/300234063250980-20161105180205-021292.sbd')
    O.read_sbd_file('poo')
    print("* Loaded sample message 3 from file.")
    print("Entire message:\n%s" % O)
    # Works... Maybe a nicer test that politely creates, md5sums, and removes.
    # O.write_sbd_file('./isbd_write_test.sbd')
    print(help)
    print()
    print(Isbdmsg.__doc__)
    print(N.dated_filename('/home/isbd/newmessages', '-%06d' % 369))
    print(M.dated_filename('/home/isbd/newmessages', '-%06d' % 370))
    print(O.dated_filename('/home/isbd/newmessages', '-%06d' % 371))


# == MAIN ==
if __name__ == '__main__':
    module_unit_test()
```

然后编写如下服务文件 `isbdd.py` ：

```python
#!/usr/bin/python
# isbdd - Iridium Short Burst Data Server
# Chris X Edwards <isbd@xed.ch>  - 2016-11-06
from _thread import start_new_thread

# Usage:
#     isbdd | tee ${SOMELOGFILE}
# What PID is listening?
#     lsof -i :10800

import isbd
import socket
import datetime

OUTDIR= './data/' # Obviously set this to make sense.
PORT= 10800  # 10800 is the normal port, but can be changed for dev testing.
HOST= ''     # Server interface to bind to. Blank is `INADDR_ANY`.
BACKLOG= 20  # Max connections on accept queue. See notes.
LOGQ= list() # Need a global queue so fast log posts don't garble each other.

def log(m):
    '''Log uses real "now" (arrival) time, not ISBD message or payload time.'''
    ts= datetime.datetime.now().strftime('%Y%m%dT%H%M%SZ') # ISO8601
    LOGQ.append( ts+':'+m ) # Append is a thread-safe operation.

# == Connection Handling For Each Thread ==
def servicethread(connection,mno,ip):
    READ_BYTES= 2048 # Optimize per application.
    data= ''
    while True:
        rdata= connection.recv(READ_BYTES)
        # data+= rdata # This may not be necessary, but allows for huge messages.
        #print 'Connection said: %s' % data
        if not rdata:
            break
        M= isbd.Isbdmsg(rdata).unpack()
        M.write_sbd_file( M.dated_filename(OUTDIR,'-%06d'%mno) )
        # M.insert_in_mysql({'host':'sql.xed.ch','user':'xedtester','passwd':'xxxxxxxxx','db':'isbd_msg'})
        #M.insert_in_pgsql(con):
        log( 'RECV:%s/%d,%s'%(ip[0],ip[1],M.log_entry()) )
    connection.close()

# == Create Socket ==
s= socket.socket(socket.AF_INET, socket.SOCK_STREAM) # I.E. (IPv4,UDP)
log( 'Socket Creation OK' )
# == Binding ==
try:
    # This line is to prevent "Bind failed! Address already in use (error #98)"
    # Which occurs if you restart the server too quickly.
    s.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
    s.bind((HOST,PORT))
except socket.error as msg:
    log( 'ERROR: Bind failed! %s (error #%s)' % (msg[1],str(msg[0])) )
    s.close()
    raise SystemExit
log('Socket Binding OK')
# == Listening ==
s.listen(BACKLOG)
log('Socket Listening on %d OK' % PORT)
# == Client Transaction ==
msg_num= int(0)
while True:
    while len(LOGQ): # Clear out queue log, i.e. don't write log concurrently.
        print(LOGQ.pop(0))
    try:
        msg_num= (msg_num+1)%1e6 # Reset to 0 after a million.
        conn,addr= s.accept()
        #log( 'Connected to %s:%d' % addr )
        start_new_thread(servicethread, (conn,msg_num,addr) )
    except KeyboardInterrupt:
        break
s.close()
log('Socket Closed OK')
```

如果需要使用 java 解析报文可以使用如下代码：

```java
import lombok.Data;
import java.nio.charset.StandardCharsets;
import java.util.Arrays;

@Data
public class Isbdmsg {

    private String msgProtocolVer;
    private Integer totalMsgLen;
    private String moHeaderIei;
    private Integer moHeaderLen;
    private Long cdrRef;
    private String imei;
    private String status;
    private Integer moMsn;
    private Integer mtMsn;
    private Long msgTimestamp;
    private String payloadHeaderIei;
    private Integer payloadHeaderLen;
    private String locOrient;
    private Integer locLatDeg;
    private Integer locLatMin;
    private Integer locLonDeg;
    private Integer locLonMin;
    private Long cepRadius;
    private String payloadIei;
    private Integer payloadLen;
    private String payload;

    public Isbdmsg(byte[] data) {
        this.msgProtocolVer = byteToHex(data[0]);
        this.totalMsgLen = ((data[1] & 0xFF) << 8) | (data[2] & 0xFF);
        this.moHeaderIei = byteToHex(data[3]);
        this.moHeaderLen = ((data[4] & 0xFF) << 8) | (data[5] & 0xFF);
        this.cdrRef = ((long)(data[6] & 0xFF) << 24) |
                ((long)(data[7] & 0xFF) << 16) |
                ((long)(data[8] & 0xFF) << 8) |
                ((long)(data[9] & 0xFF));
        this.imei = new String(Arrays.copyOfRange(data,10,25), StandardCharsets.UTF_8);
        this.status = byteToHex(data[25]);
        this.moMsn = ((data[26] & 0xFF) << 8) | (data[27] & 0xFF);
        this.mtMsn = ((data[28] & 0xFF) << 8) | (data[29] & 0xFF);
        this.msgTimestamp = ((long)(data[30] & 0xFF) << 24) |
                ((long)(data[31] & 0xFF) << 16) |
                ((long)(data[32] & 0xFF) << 8) |
                ((long)(data[33] & 0xFF));
        this.payloadHeaderIei = byteToHex(data[34]);
        this.payloadHeaderLen = ((data[35] & 0xFF) << 8) | (data[36] & 0xFF);
        this.locOrient = String.valueOf(data[37]);
        this.locLatDeg = Integer.valueOf(String.valueOf(data[38]));
        this.locLatMin = ((data[39] & 0xFF) << 8) | (data[40] & 0xFF);
        this.locLonDeg = Integer.valueOf(String.valueOf(data[41]));
        this.locLonMin = ((data[42] & 0xFF) << 8) | (data[43] & 0xFF);
        this.cepRadius = ((long)(data[44] & 0xFF) << 24) |
                ((long)(data[45] & 0xFF) << 16) |
                ((long)(data[46] & 0xFF) << 8) |
                ((long)(data[47] & 0xFF));
        this.payloadIei = byteToHex(data[48]);
        this.payloadLen = ((data[49] & 0xFF) << 8) | (data[50] & 0xFF);
        this.payload = new String(Arrays.copyOfRange(data,51,data.length), StandardCharsets.UTF_8);
    }

    public static String byteToHex(byte b) {
        return String.format("%02X", b);
    }
}
```

并如下改动 netty 接收代码：

```
import io.netty.buffer.ByteBuf;
import io.netty.channel.ChannelHandlerContext;
import io.netty.channel.ChannelInboundHandlerAdapter;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Component;

@Slf4j
@Component
public class DiscardServerHandler extends ChannelInboundHandlerAdapter {

    @Override
    public void channelRead(ChannelHandlerContext ctx, Object msg) {
        ByteBuf in = (ByteBuf) msg;
        try {
            Isbdmsg isbdmsg = new Isbdmsg(in.toString().getBytes());
            log.error(isbdmsg.getPayload());
        } finally {
            in.release();
        }
    }

    @Override
    public void exceptionCaught(ChannelHandlerContext ctx, Throwable cause) {
        cause.printStackTrace();
        ctx.close();
    }

}
```

### 参考资料

[Iridium Short Burst Data Python Module](https://xed.ch/project/isbd/)
