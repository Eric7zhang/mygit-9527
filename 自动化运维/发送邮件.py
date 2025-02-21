import smtplib
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from email.header import Header
import traceback

def send_email():
    try:
        sender_email = "zxf8517@sohu.com"
        receiver_email = "zxf8517@icloud.com"
        password = "32MZBQWSLINK"  # 请替换为您的真实密码

        # 创建邮件对象
        msg = MIMEMultipart()
        msg['From'] = Header(sender_email, 'utf-8')
        msg['To'] = Header(receiver_email, 'utf-8')
        msg['Subject'] = Header("日常巡检", 'utf-8')

        # 简单的邮件正文
        body = "这是一个简单的日常巡检邮件，请忽略广告等内容。"
        msg.attach(MIMEText(body, 'plain', 'utf-8'))

        # 使用 SMTP 连接发送邮件
        with smtplib.SMTP("smtp.sohu.com", 25) as server:
            server.set_debuglevel(1)  # 打开调试信息
            server.ehlo()  # 初始化连接
            server.login(sender_email, password)  # 登录
            server.send_message(msg)  # 发送邮件
            print("邮件发送成功！")
    except Exception as e:
        print(f"邮件发送失败：{e}")
        traceback.print_exc()

if __name__ == "__main__":
    send_email()
