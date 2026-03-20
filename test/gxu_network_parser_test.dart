import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/repository/gxu_ids/gxu_network_parser.dart';

void main() {
  group('GxuNetworkParser', () {
    final parser = GxuNetworkParser();

    test('parses dashboard usage fields from normalized page text', () {
      const html = '''
      <html>
        <body>
          <div class="panel-body">
            <div class="row">
              <div class="col-xs-6">
                <dl>
                  <dt>182188 <small class="unit">M</small></dt>
                  <dd>已用流量</dd>
                </dl>
              </div>
              <div class="col-xs-6">
                <dl>
                  <dt>0 <small class="unit">M</small></dt>
                  <dd>免费流量</dd>
                </dl>
              </div>
              <div class="col-xs-6">
                <dl>
                  <dt>-1 <small class="unit">M</small></dt>
                  <dd>可用流量</dd>
                </dl>
              </div>
              <div class="col-xs-6">
                <dl>
                  <dt>未设置</dt>
                  <dd>消费保护</dd>
                </dl>
              </div>
              <div class="col-xs-6">
                <dl>
                  <dt>80.00 <small class="unit">元</small></dt>
                  <dd>账户余额</dd>
                </dl>
              </div>
            </div>
            <div class="row">
              <label class="col-md-3 col-xs-5 text-right">账　　号：</label>
              <div class="col-md-9 col-xs-7"><span>20230001</span></div>
            </div>
            <div class="row">
              <label class="col-md-3 col-xs-5 text-right">计费周期：</label>
              <div class="col-md-9 col-xs-7">
                <span><span class="label-default">2026-03-01</span> 至 <span class="label-default">2026-03-31</span></span>
              </div>
            </div>
          </div>
        </body>
      </html>
      ''';

      final usage = parser.parseDashboard(html: html, account: '20230001');

      expect(usage.account, '20230001');
      expect(usage.settlementDate, '2026-03-31');
      expect(usage.usedTraffic, '182188 M');
      expect(usage.freeTraffic, '0 M');
      expect(usage.availableTraffic, '-1 M');
      expect(usage.protection, '未设置');
      expect(usage.balance, '80.00 元');
    });

    test('extracts login form data and error tip', () {
      const html = '''
      <html>
        <body>
          <h3>欢迎登录用户自助服务系统</h3>
          <form action="/login/verify;jsessionid=ABC123" method="post">
            <input type="hidden" name="checkcode" value="781" />
          </form>
          <img src="/login/randomCode?t=1" />
          <script>
            (function (tip) {
              if (tip != null) {}
            })('验证码错误！');
          </script>
        </body>
      </html>
      ''';

      expect(parser.isLoginPage(html), isTrue);
      expect(parser.extractFormAction(html), '/login/verify;jsessionid=ABC123');
      expect(parser.extractCheckCode(html), '781');
      expect(parser.extractLoginError(html), '验证码错误！');
    });
  });
}
