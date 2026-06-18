// part 'treeData.g.dart';

// 如果你的项目里没有定义，可以临时用 Map；有模型类则直接用模型
class TreeNode {
  final String id;
  final String name;
  final String type; // 例如：department, team, employee
  final List<TreeNode>? children;

  TreeNode({
    required this.id,
    required this.name,
    required this.type,
    this.children,
  });

  // 方便从 Map 转换的工厂构造（可选）
  factory TreeNode.fromMap(Map<String, dynamic> map) {
    return TreeNode(
      id: map['id'],
      name: map['name'],
      type: map['type'],
      children: (map['children'] ?? [])
          .map((e) => TreeNode.fromMap(e))
          .toList(),
    );
  }
}

final Map<String, dynamic> treeMockData = {
  "id": "root_001",
  "name": "星辰科技集团",
  "type": "company",
  "children": [
    {
      "id": "dept_01",
      "name": "研发中心",
      "type": "department",
      "children": [
        {
          "id": "team_01",
          "name": "前端开发组",
          "type": "team",
          "children": [
            {"id": "emp_01", "name": "张小明", "type": "employee", "children": []},
            {"id": "emp_02", "name": "李小红", "type": "employee", "children": []},
            {"id": "emp_03", "name": "王德华", "type": "employee", "children": []},
          ],
        },
        {
          "id": "team_02",
          "name": "后端开发组",
          "type": "team",
          "children": [
            {"id": "emp_04", "name": "赵子龙", "type": "employee", "children": []},
            {"id": "emp_05", "name": "陈双全", "type": "employee", "children": []},
            {
              "id": "team_02_sub",
              "name": "数据库专项组",
              "type": "team",
              "children": [
                {
                  "id": "emp_06",
                  "name": "刘三石",
                  "type": "employee",
                  "children": [],
                },
              ],
            },
          ],
        },
      ],
    },
    {
      "id": "dept_02",
      "name": "产品中心",
      "type": "department",
      "children": [
        {
          "id": "team_03",
          "name": "产品策划组",
          "type": "team",
          "children": [
            {"id": "emp_07", "name": "林产品", "type": "employee", "children": []},
            {"id": "emp_08", "name": "何交互", "type": "employee", "children": []},
          ],
        },
      ],
    },
    {
      "id": "dept_03",
      "name": "运营中心",
      "type": "department",
      "children": [
        {"id": "emp_09", "name": "黄运营", "type": "employee", "children": []},
      ],
    },
  ],
};
