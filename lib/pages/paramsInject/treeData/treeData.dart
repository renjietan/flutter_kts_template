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

final Map<String, dynamic> mockData1 = {
  "id": "root_002",
  "name": "天启科技",
  "type": "company",
  "children": [
    {
      "id": "dept_01",
      "name": "技术研发中心",
      "type": "department",
      "children": [
        {
          "id": "team_01",
          "name": "前端架构组",
          "type": "team",
          "children": [
            {"id": "emp_01", "name": "张伟", "type": "employee", "children": []},
            {"id": "emp_02", "name": "李娜", "type": "employee", "children": []},
            {"id": "emp_03", "name": "王强", "type": "employee", "children": []},
          ],
        },
        {
          "id": "team_02",
          "name": "后端开发组",
          "type": "team",
          "children": [
            {"id": "emp_04", "name": "刘洋", "type": "employee", "children": []},
            {"id": "emp_05", "name": "陈晨", "type": "employee", "children": []},
            {
              "id": "team_02_sub",
              "name": "数据库专项组",
              "type": "team",
              "children": [
                {
                  "id": "emp_06",
                  "name": "赵敏",
                  "type": "employee",
                  "children": [],
                },
                {
                  "id": "emp_07",
                  "name": "黄海",
                  "type": "employee",
                  "children": [],
                },
              ],
            },
          ],
        },
        {
          "id": "team_03",
          "name": "算法研究组",
          "type": "team",
          "children": [
            {"id": "emp_08", "name": "周杰", "type": "employee", "children": []},
            {"id": "emp_09", "name": "吴迪", "type": "employee", "children": []},
          ],
        },
      ],
    },
    {
      "id": "dept_02",
      "name": "市场营销部",
      "type": "department",
      "children": [
        {
          "id": "team_04",
          "name": "品牌策划组",
          "type": "team",
          "children": [
            {"id": "emp_10", "name": "徐静", "type": "employee", "children": []},
          ],
        },
        {
          "id": "team_05",
          "name": "数字推广组",
          "type": "team",
          "children": [
            {"id": "emp_11", "name": "孙阳", "type": "employee", "children": []},
            {"id": "emp_12", "name": "林欣", "type": "employee", "children": []},
          ],
        },
      ],
    },
    {
      "id": "dept_03",
      "name": "人力资源部",
      "type": "department",
      "children": [
        {"id": "emp_13", "name": "何慧", "type": "employee", "children": []},
        {"id": "emp_14", "name": "罗敏", "type": "employee", "children": []},
      ],
    },
  ],
};

final Map<String, dynamic> mockData2 = {
  "id": "root_003",
  "name": "华信集团",
  "type": "company",
  "children": [
    {
      "id": "dept_01",
      "name": "产品事业部",
      "type": "department",
      "children": [
        {
          "id": "team_01",
          "name": "产品设计组",
          "type": "team",
          "children": [
            {"id": "emp_01", "name": "高敏", "type": "employee", "children": []},
            {"id": "emp_02", "name": "郑洁", "type": "employee", "children": []},
          ],
        },
        {
          "id": "team_02",
          "name": "需求分析组",
          "type": "team",
          "children": [
            {"id": "emp_03", "name": "沈涛", "type": "employee", "children": []},
            {"id": "emp_04", "name": "韩梅", "type": "employee", "children": []},
            {
              "id": "team_02_sub",
              "name": "用户体验专项组",
              "type": "team",
              "children": [
                {
                  "id": "emp_05",
                  "name": "秦岚",
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
      "name": "技术事业部",
      "type": "department",
      "children": [
        {
          "id": "team_03",
          "name": "开发一组",
          "type": "team",
          "children": [
            {"id": "emp_06", "name": "许峰", "type": "employee", "children": []},
            {"id": "emp_07", "name": "蒋欣", "type": "employee", "children": []},
            {"id": "emp_08", "name": "卢伟", "type": "employee", "children": []},
          ],
        },
        {
          "id": "team_04",
          "name": "开发二组",
          "type": "team",
          "children": [
            {"id": "emp_09", "name": "蔡琳", "type": "employee", "children": []},
            {
              "id": "team_04_sub",
              "name": "质量保障组",
              "type": "team",
              "children": [
                {
                  "id": "emp_10",
                  "name": "余建",
                  "type": "employee",
                  "children": [],
                },
                {
                  "id": "emp_11",
                  "name": "夏云",
                  "type": "employee",
                  "children": [],
                },
              ],
            },
          ],
        },
        {
          "id": "team_05",
          "name": "运维保障组",
          "type": "team",
          "children": [
            {"id": "emp_12", "name": "顾磊", "type": "employee", "children": []},
          ],
        },
      ],
    },
    {
      "id": "dept_03",
      "name": "综合管理部",
      "type": "department",
      "children": [
        {"id": "emp_13", "name": "邵颖", "type": "employee", "children": []},
        {"id": "emp_14", "name": "孟波", "type": "employee", "children": []},
        {"id": "emp_15", "name": "龙威", "type": "employee", "children": []},
      ],
    },
  ],
};
