import 'package:flutter_test/flutter_test.dart';
import 'package:watermeter/model/gxu_ids/gxu_empty_classroom.dart';
import 'package:watermeter/repository/auth_exceptions.dart';
import 'package:watermeter/repository/gxu_ids/gxu_empty_classroom_parser.dart';

void main() {
  group("GxuEmptyClassroomParser", () {
    final parser = GxuEmptyClassroomParser();

    test("parseQueryPage extracts toolbar selects and numeric inputs", () {
      const html = '''
      <html>
        <body>
          <div class="cxkxjs">
            <div class="toolbar">
              <div class="form-group">
                <span class="sameRow-label">开课学期:</span>
                <select name="xqdm">
                  <option value="">请选择</option>
                  <option value="2025-2026-2" selected>2026年春季</option>
                </select>
              </div>
              <div class="form-group">
                <span class="sameRow-label">选择周次:</span>
                <select name="kszc"><option value="1" selected>第1周</option></select>
                <select name="jszc"><option value="20" selected>第20周</option></select>
              </div>
              <div class="form-group">
                <span class="sameRow-label">选择星期:</span>
                <select name="ksxq"><option value="1" selected>星期一</option></select>
                <select name="jsxq"><option value="7" selected>星期日</option></select>
              </div>
              <div class="form-group">
                <span class="sameRow-label">选择节次:</span>
                <select name="ksjc"><option value="1" selected>第1节</option></select>
                <select name="jsjc"><option value="13" selected>第13节</option></select>
              </div>
              <div class="form-group">
                <span class="sameRow-label">教学楼:</span>
                <select name="jxlh"></select>
              </div>
              <div class="form-group">
                <span class="sameRow-label">教室:</span>
                <select name="jsxxid" multiple></select>
              </div>
              <div class="form-group">
                <span class="sameRow-label">座位数:</span>
                <input name="zws" />
                <input name="jszws" />
              </div>
              <div class="form-group">
                <span class="sameRow-label">占用情况:</span>
                <select name="zyqk" multiple>
                  <option value="">请选择</option>
                  <option value="00">借用</option>
                </select>
              </div>
              <div class="form-group">
                <span class="sameRow-label">占用类型:</span>
                <select name="zylx">
                  <option value="">请选择</option>
                  <option value="1">研究生占用</option>
                </select>
              </div>
            </div>
          </div>
        </body>
      </html>
      ''';

      final form = parser.parseQueryPage(html);

      expect(form.viewType, GxuEmptyClassroomViewType.period);
      expect(form.selectField("xqdm")?.selectedValue, "2025-2026-2");
      expect(form.selectField("kszc")?.selectedValue, "1");
      expect(form.selectField("jszc")?.selectedValue, "20");
      expect(form.selectField("ksxq")?.selectedValue, "1");
      expect(form.selectField("jsxq")?.selectedValue, "7");
      expect(form.selectField("ksjc")?.selectedValue, "1");
      expect(form.selectField("jsjc")?.selectedValue, "13");
      expect(form.selectField("jxlh")?.options, isEmpty);
      expect(form.selectField("jsxxid")?.isMulti, isTrue);
      expect(form.textField("zws")?.label, "座位数");
      expect(form.textField("jszws")?.label, "座位数");
    });

    test("parseQueryPage throws when range selects have no usable options", () {
      const html = '''
      <html>
        <body>
          <div class="cxkxjs">
            <div class="toolbar">
              <div class="form-group"><select name="xqdm"><option value="">请选择</option></select></div>
              <div class="form-group"><select name="kszc"><option value="1" selected>第1周</option></select></div>
              <div class="form-group"><select name="jszc"><option value="20" selected>第20周</option></select></div>
              <div class="form-group"><select name="ksxq"><option value="1" selected>星期一</option></select></div>
              <div class="form-group"><select name="jsxq"><option value="7" selected>星期日</option></select></div>
              <div class="form-group"><select name="ksjc"><option value="1" selected>第1节</option></select></div>
              <div class="form-group"><select name="jsjc"><option value="13" selected>第13节</option></select></div>
              <div class="form-group"><select name="jxlh"></select></div>
              <div class="form-group"><select name="jsxxid" multiple></select></div>
              <div class="form-group"><select name="zyqk" multiple><option value="">请选择</option></select></div>
              <div class="form-group"><select name="zylx"><option value="">请选择</option></select></div>
            </div>
          </div>
        </body>
      </html>
      ''';
      expect(
        () => parser.parseQueryPage(html),
        throwsA(
          predicate(
            (err) =>
                err is LoginFailedException &&
                err.msg.contains("可用选项") &&
                err.msg.contains("xqdm"),
          ),
        ),
      );
    });

    test("withClassroomCatalog fills building and classroom options", () {
      const html = '''
      <html>
        <body>
          <div class="cxkxjs">
            <div class="toolbar">
              <div class="form-group"><span class="sameRow-label">开课学期:</span><select name="xqdm"><option value="2025-2026-2" selected>2026年春季</option></select></div>
              <div class="form-group"><span class="sameRow-label">选择周次:</span><select name="kszc"><option value="1" selected>第1周</option></select></div>
              <div class="form-group"><span class="sameRow-label">选择周次:</span><select name="jszc"><option value="20" selected>第20周</option></select></div>
              <div class="form-group"><span class="sameRow-label">选择星期:</span><select name="ksxq"><option value="1" selected>星期一</option></select></div>
              <div class="form-group"><span class="sameRow-label">选择星期:</span><select name="jsxq"><option value="7" selected>星期日</option></select></div>
              <div class="form-group"><span class="sameRow-label">选择节次:</span><select name="ksjc"><option value="1" selected>第1节</option></select></div>
              <div class="form-group"><span class="sameRow-label">选择节次:</span><select name="jsjc"><option value="13" selected>第13节</option></select></div>
              <div class="form-group"><span class="sameRow-label">教学楼:</span><select name="jxlh"></select></div>
              <div class="form-group"><span class="sameRow-label">教室:</span><select name="jsxxid" multiple></select></div>
              <div class="form-group"><span class="sameRow-label">占用情况:</span><select name="zyqk" multiple><option value="">请选择</option></select></div>
              <div class="form-group"><span class="sameRow-label">占用类型:</span><select name="zylx"><option value="">请选择</option></select></div>
            </div>
          </div>
        </body>
      </html>
      ''';
      final baseForm = parser.parseQueryPage(html);
      final form = baseForm.withClassroomCatalog([
        const GxuEmptyClassroomCatalogRoom(
          id: "10B-306",
          name: "东10B-306",
          building: "东十教",
          campusCode: "1",
          campusName: "主校区",
          availableSeats: "48",
          examSeats: "24",
          statusCode: "1",
          statusLabel: "可以使用",
        ),
        const GxuEmptyClassroomCatalogRoom(
          id: "15-105",
          name: "15-105",
          building: "十五教",
          campusCode: "1",
          campusName: "主校区",
          availableSeats: "90",
          examSeats: "0",
          statusCode: "1",
          statusLabel: "可以使用",
        ),
      ]);

      expect(form.selectField("jxlh")?.options, hasLength(3));
      expect(form.selectField("jsxxid")?.options, hasLength(3));

      final narrowed = form.updateSelect("jxlh", ["东十教"]);
      expect(narrowed.selectField("jsxxid")?.options, hasLength(2));
      expect(narrowed.selectField("jsxxid")?.options.last.value, "10B-306");
    });

    test("parseResultPayload builds rows for the selected view", () {
      final result = parser.parseResultPayload({
        "data": [
          {
            "jsxxid": "10B-306",
            "jsmc": "东10B-306",
            "jsztdm": "1",
            "yxzws": 48,
            "kszws": 24,
            "jk": {"jc6": 2},
            "ks": {},
            "jy": {},
            "tk": {},
            "qt": {},
          },
          {
            "jsxxid": "15-105",
            "jsmc": "15-105",
            "jsztdm": "1",
            "bkszbky": true,
            "yxzws": 90,
            "kszws": 0,
          },
          {
            "jsxxid": "16-101",
            "jsmc": "16-101",
            "jsztdm": "1",
            "yxzws": 58,
            "kszws": 30,
          },
        ],
      });
      final form = GxuEmptyClassroomQueryForm(
        viewType: GxuEmptyClassroomViewType.period,
        selectFields: const [
          GxuEmptyClassroomSelectField(
            name: "kszc",
            label: "开始周次",
            options: [],
            selectedValues: ["1"],
          ),
          GxuEmptyClassroomSelectField(
            name: "jszc",
            label: "结束周次",
            options: [],
            selectedValues: ["20"],
          ),
          GxuEmptyClassroomSelectField(
            name: "ksxq",
            label: "开始星期",
            options: [],
            selectedValues: ["1"],
          ),
          GxuEmptyClassroomSelectField(
            name: "jsxq",
            label: "结束星期",
            options: [],
            selectedValues: ["7"],
          ),
          GxuEmptyClassroomSelectField(
            name: "ksjc",
            label: "开始节次",
            options: [],
            selectedValues: ["5"],
          ),
          GxuEmptyClassroomSelectField(
            name: "jsjc",
            label: "结束节次",
            options: [],
            selectedValues: ["6"],
          ),
        ],
        textFields: const [],
        classroomCatalog: const [
          GxuEmptyClassroomCatalogRoom(
            id: "10B-306",
            name: "东10B-306",
            building: "东十教",
            campusCode: "1",
            campusName: "主校区",
            availableSeats: "48",
            examSeats: "24",
            statusCode: "1",
            statusLabel: "可以使用",
          ),
          GxuEmptyClassroomCatalogRoom(
            id: "15-105",
            name: "15-105",
            building: "十五教",
            campusCode: "1",
            campusName: "主校区",
            availableSeats: "90",
            examSeats: "0",
            statusCode: "1",
            statusLabel: "可以使用",
          ),
          GxuEmptyClassroomCatalogRoom(
            id: "16-101",
            name: "16-101",
            building: "十六教",
            campusCode: "1",
            campusName: "主校区",
            availableSeats: "58",
            examSeats: "30",
            statusCode: "1",
            statusLabel: "可以使用",
          ),
        ],
      );

      final rows = result.buildRows(form: form);

      expect(rows, hasLength(3));
      expect(rows.first.title, "16-101");
      expect(rows.first.availableCount, 2);
      expect(rows[1].cells.last.state, GxuEmptyClassroomCellState.occupied);
      expect(rows[1].cells.last.shortLabel, "排课");
      expect(
        rows.last.cells.first.state,
        GxuEmptyClassroomCellState.unavailable,
      );
      expect(rows.last.cells.first.localDetailMessage, "本科设置为不可用教室");
    });

    test("remote room treats numeric/string bkszbky as unavailable", () {
      final numeric = GxuEmptyClassroomRemoteRoom.fromJson({
        "jsxxid": "15-201",
        "jsmc": "15-201",
        "jsztdm": "1",
        "yxzws": 0,
        "kszws": 0,
        "bkszbky": 1,
      });
      final stringValue = GxuEmptyClassroomRemoteRoom.fromJson({
        "jsxxid": "15-202",
        "jsmc": "15-202",
        "jsztdm": "1",
        "yxzws": 0,
        "kszws": 0,
        "bkszbky": "1",
      });

      expect(numeric.undergraduateUnavailable, isTrue);
      expect(stringValue.undergraduateUnavailable, isTrue);
    });

    test("parseDetailPayload joins all returned detail lines", () {
      final detail = parser.parseDetailPayload({
        "data": {"jk": "研究生场地冲突", "ks": "", "jy": "预约场地冲突", "tk": "", "qt": ""},
      });

      expect(detail, contains("排课信息：研究生场地冲突"));
      expect(detail, contains("借用信息：预约场地冲突"));
    });

    test("parseDetailPayload ignores placeholder 0 and 0.0 values", () {
      final detail = parser.parseDetailPayload({
        "data": {"jk": "0", "ks": 0, "jy": "0.0", "tk": 0.0, "qt": ""},
      });

      expect(detail, "未查询到占用详情");
    });
  });
}
