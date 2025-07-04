## LeetCode 学习记录

### 哈希

#### 两数之和

```java
class Solution {
    public int[] twoSum(int[] nums, int target) {
        Map<Integer,Integer> map = new HashMap<>();
        for (int i = 0; i < nums.length; i++) {
            if (map.containsKey(nums[i])) {
                return new int[]{map.get(nums[i]), i};
            }
            map.put(target - nums[i], i);
        }
        return new int[0];
    }
}
```

[官方题目](https://leetcode.cn/problems/two-sum)

#### 字母异位词分组

```java
class Solution {
    public List<List<String>> groupAnagrams(String[] strs) {
        Map<String, List<String>> map = new HashMap<String, List<String>>();
        for (String str : strs) {
            char[] array = str.toCharArray();
            Arrays.sort(array);
            String key = new String(array);
            List<String> list = map.getOrDefault(key, new ArrayList<String>());
            list.add(str);
            map.put(key, list);
        }
        return new ArrayList<List<String>>(map.values());
    }
}
```

[官方题目](https://leetcode.cn/problems/group-anagrams)

#### 最长连续序列

```java
class Solution {
    public int longestConsecutive(int[] nums) {
        HashSet<Integer> set = new HashSet<>();
        for (int num : nums) {
            set.add(num);
        }
        int longestStreak = 0;
        for (int num : set) {
            if (!set.contains(num - 1)) {
                int currentNum = num;
                int currentStreak = 1;
                while (set.contains(currentNum + 1)) {
                    currentNum += 1;
                    currentStreak += 1;
                }
                longestStreak = Math.max(longestStreak, currentStreak);
            }
        }
        return longestStreak;
    }
}
```

[最长连续序列](https://leetcode.cn/problems/longest-consecutive-sequence)

### 双指针

#### 移动零

```java
class Solution {
    public void moveZeroes(int[] nums) {
        int n=nums.length;
        int fast=0;
        int slow=0;
        for (;fast<n;fast++){
            if (nums[fast]!=0){
                nums[slow]=nums[fast];
                slow++;
            }
        }
        for (;slow<n;slow++){
            nums[slow]=0;
        }
    }
}
```

[移动零](https://leetcode.cn/problems/move-zeroes)

#### 盛最多水的容器

```java
class Solution {
    public int maxArea(int[] height) {
        int left = 0;
        int right = height.length-1;
        int maxArea = 0;
        while (left < right) {
            int area;
            if (height[left] >= height[right]) {
                area = (right-left)*height[right];
                --right;
            } else {
                area = (right-left)*height[left];
                ++left;
            }
            maxArea = Math.max(maxArea, area);
        }
        return maxArea;
    }
}
```

[盛最多水的容器](https://leetcode.cn/problems/container-with-most-water)

#### 三数之和

```java
class Solution {
    public List<List<Integer>> threeSum(int[] nums) {
        Arrays.sort(nums);
        List<List<Integer>> result = new ArrayList();
        int len = nums.length;
        for(int i=0;i<len;i++) {
            if(nums[i] > 0) break;
            if(i > 0 && nums[i] == nums[i-1]) continue;
            int l = i+1;
            int r = len -1;
            while(l<r) {
                int sum = nums[i] + nums[l] + nums[r];
                if(sum ==0) {
                    result.add(Arrays.asList(nums[i],nums[l],nums[r]));
                    while (l < r && nums[l] == nums[l + 1]) {
                        l++;
                    }
                    while (l < r && nums[r] == nums[r - 1]) {
                        r--;
                    }
                    l++;
                    r--;
                } else if (sum > 0) {
                    r--;
                } else {
                    l++;
                }
            }
        }
        return result;
    }
}
```

[三数之和](https://leetcode.cn/problems/3sum)

#### 接雨水

```java
class Solution {
    public int trap(int[] height) {
        int left = 0, right = height.length - 1;
        int leftMax = 0, rightMax = 0, result = 0;

        while (left < right) {
            if (height[left] < height[right]) {
                if (height[left] >= leftMax) {
                    leftMax = height[left];
                } else {
                    result += leftMax - height[left];
                }
                left++;
            } else {
                if (height[right] >= rightMax) {
                    rightMax = height[right];
                } else {
                    result += rightMax - height[right];
                }
                right--;
            }
        }
        return result;
    }
}
```

[接雨水](https://leetcode.cn/problems/trapping-rain-water)

#### 无重复字符的最长子串

```java
class Solution {
    public int lengthOfLongestSubstring(String s) {
        Map<Character, Integer> map = new HashMap<>();
        int maxLen = 0, slow = 0;
        for (int fast = 0; fast < s.length(); fast++) {
            char c = s.charAt(fast);
            if (map.containsKey(c)) {
                slow = Math.max(slow, map.get(c) + 1);
            }
            map.put(c, fast);
            maxLen = Math.max(maxLen, fast - slow + 1);
        }
        return maxLen;
    }
}
```

[无重复字符的最长子串](https://leetcode.cn/problems/longest-substring-without-repeating-characters)

#### 找到字符串中所有字母异位词

```java
class Solution {
    public List<Integer> findAnagrams(String s, String p) {
        int sLen = s.length(), pLen = p.length();

        if (sLen < pLen) {
            return new ArrayList<Integer>();
        }

        List<Integer> ans = new ArrayList<Integer>();
        int[] count = new int[26];
        for (int i = 0; i < pLen; ++i) {
            ++count[s.charAt(i) - 'a'];
            --count[p.charAt(i) - 'a'];
        }

        int differ = 0;
        for (int j = 0; j < 26; ++j) {
            if (count[j] != 0) {
                ++differ;
            }
        }

        if (differ == 0) {
            ans.add(0);
        }

        for (int i = 0; i < sLen - pLen; ++i) {
            if (count[s.charAt(i) - 'a'] == 1) {
                --differ;
            } else if (count[s.charAt(i) - 'a'] == 0) {
                ++differ;
            }
            --count[s.charAt(i) - 'a'];

            if (count[s.charAt(i + pLen) - 'a'] == -1) {
                --differ;
            } else if (count[s.charAt(i + pLen) - 'a'] == 0) {
                ++differ;
            }
            ++count[s.charAt(i + pLen) - 'a'];
            
            if (differ == 0) {
                ans.add(i + 1);
            }
        }

        return ans;
    }
}
```

[找到字符串中所有字母异位词](https://leetcode.cn/problems/find-all-anagrams-in-a-string)

#### 和为 K 的子数组


```python
public class Solution {
    public int subarraySum(int[] nums, int k) {
        int count = 0, pre = 0;
        HashMap < Integer, Integer > mp = new HashMap < > ();
        mp.put(0, 1);
        for (int i = 0; i < nums.length; i++) {
            pre += nums[i];
            if (mp.containsKey(pre - k)) {
                count += mp.get(pre - k);
            }
            mp.put(pre, mp.getOrDefault(pre, 0) + 1);
        }
        return count;
    }
}
```

[和为 K 的子数组](https://leetcode.cn/problems/subarray-sum-equals-k)

#### 滑动窗口最大值

```java
class Solution {
    public int[] maxSlidingWindow(int[] nums, int k) {
        if (nums == null || nums.length == 0) return new int[0];
        
        int n = nums.length;
        int[] result = new int[n - k + 1];
        Deque<Integer> deque = new LinkedList<>();
        int idx = 0; // 结果数组的索引

        for (int i = 0; i < nums.length; i++) {
            // 1. 移除超出窗口范围的索引（队首）
            while (!deque.isEmpty() && deque.peekFirst() < i - k + 1) {
                deque.pollFirst();
            }

            // 2. 移除比当前元素小的索引（队尾）
            while (!deque.isEmpty() && nums[deque.peekLast()] < nums[i]) {
                deque.pollLast();
            }

            // 3. 添加当前元素索引
            deque.offerLast(i);

            // 4. 记录窗口最大值
            if (i >= k - 1) {
                result[idx++] = nums[deque.peekFirst()];
            }
        }

        return result;
    }
}
```

[滑动窗口最大值](https://leetcode.cn/problems/sliding-window-maximum)

#### 最小覆盖子串

```java
public class Solution {
    public String minWindow(String s, String t) {
        // 记录目标字符串 t 的字符需求
        Map<Character, Integer> need = new HashMap<>();
        // 记录当前窗口中的字符数量
        Map<Character, Integer> window = new HashMap<>();

        // 初始化 need 表
        for (char c : t.toCharArray()) {
            need.put(c, need.getOrDefault(c, 0) + 1);
        }

        // 双指针
        int left = 0;
        int right = 0;

        // 匹配计数：valid 表示当前窗口满足 need 条件的字符个数
        int valid = 0;

        // 最小覆盖子串的起始索引和长度
        int start = 0;
        int minLength = Integer.MAX_VALUE;

        while (right < s.length()) {
            char c = s.charAt(right);
            right++;

            // 如果当前字符是需要的，则加入窗口并更新 valid
            if (need.containsKey(c)) {
                window.put(c, window.getOrDefault(c, 0) + 1);
                // 判断是否已经满足了该字符的需求
                if (window.get(c).equals(need.get(c))) {
                    valid++;
                }
            }

            // 当窗口满足条件时，尝试收缩左边界以获取更小窗口
            while (valid == need.size()) {
                // 更新最小窗口
                if (right - left < minLength) {
                    start = left;
                    minLength = right - left;
                }

                char d = s.charAt(left);
                left++;

                // 如果移出的是目标字符，更新窗口信息
                if (need.containsKey(d)) {
                    if (window.get(d).equals(need.get(d))) {
                        valid--;
                    }
                    window.put(d, window.get(d) - 1);
                }
            }
        }

        // 返回最小覆盖子串
        return minLength == Integer.MAX_VALUE ? "" : s.substring(start, start + minLength);
    }
}
```

[最小覆盖子串](https://leetcode.cn/problems/minimum-window-substring)

#### 最大子数组和

```java
class Solution {
    public int maxSubArray(int[] nums) {
        // 如果数组为空或长度为0，返回0或抛异常均可
        if (nums == null || nums.length == 0) {
            return 0;
        }

        // 当前子数组的和
        int currentSum = nums[0];
        // 最大子数组和
        int maxSum = nums[0];

        // 从第二个元素开始遍历
        for (int i = 1; i < nums.length; i++) {
            // 如果当前子数组和为负数，则舍弃前面的子数组，从当前元素重新开始
            currentSum = Math.max(nums[i], currentSum + nums[i]);

            // 更新最大子数组和
            maxSum = Math.max(maxSum, currentSum);
        }

        return maxSum;
    }
}
```

[最大子数组和](https://leetcode.cn/problems/maximum-subarray)

#### 合并区间

```java
class Solution {
    public int[][] merge(int[][] intervals) {
        if (intervals == null || intervals.length == 0) {
            return new int[0][];
        }

        // 按照区间的起始点排序
        Arrays.sort(intervals, (a, b) -> a[0] - b[0]);

        List<int[]> merged = new ArrayList<>();
        for (int[] interval : intervals) {
            // 如果列表为空或者当前区间不与上一个区间重叠，直接加入
            if (merged.isEmpty() || merged.get(merged.size() - 1)[1] < interval[0]) {
                merged.add(interval);
            } else {
                // 否则合并
                merged.get(merged.size() - 1)[1] = Math.max(merged.get(merged.size() - 1)[1], interval[1]);
            }
        }

        // 转换为二维数组返回
        return merged.toArray(new int[merged.size()][]);
    }
}
```

[合并区间](https://leetcode.cn/problems/merge-intervals)

#### 轮转数组

```java
class Solution {
    public void rotate(int[] nums, int k) {
        int n = nums.length;
        k = k % n;  // 避免多余的旋转
        
        int count = 0;  // 已处理元素个数
        int start = 0;  // 起始点

        while (count < n) {
            int current = start;
            int prev = nums[current];
            
            do {
                int next = (current + k) % n;
                int temp = nums[next];
                nums[next] = prev;
                prev = temp;
                current = next;
                count++;
                
            } while (current != start);  // 直到回到起点
            
            start++;  // 处理下一个环
        }
    }
}
```

[轮转数组](https://leetcode.cn/problems/rotate-array)

#### 除自身以外数组的乘积

```java
class Solution {
    public static int[] productExceptSelf(int[] nums) {
        int n = nums.length;
        int[] answer = new int[n];

        // 第一步：计算每个元素左边所有元素的乘积
        answer[0] = 1; // 第一个元素左边没有元素，乘积为1
        for (int i = 1; i < n; i++) {
            answer[i] = answer[i - 1] * nums[i - 1];
        }

        // 第二步：计算每个元素右边所有元素的乘积，并乘到answer数组上
        int R = 1; // 用于记录当前元素右边的乘积
        for (int i = n - 1; i >= 0; i--) {
            answer[i] = answer[i] * R;
            R *= nums[i]; // 更新R，为下一个元素的右边乘积
        }

        return answer;
    }
}
```

[除自身以外数组的乘积](https://leetcode.cn/problems/product-of-array-except-self)

#### 缺失的第一个正数

```java
class Solution {
    public static int firstMissingPositive(int[] nums) {
        int n = nums.length;

        // 第一步：将每个 1~n 范围内的数放到它应该在的位置
        for (int i = 0; i < n; i++) {
            // 只处理 1~n 的数，并且确保不会死循环（nums[i] != nums[nums[i] - 1]）
            while (nums[i] > 0 && nums[i] <= n && nums[i] != nums[nums[i] - 1]) {
                // 将 nums[i] 放到正确的位置上
                int correctIndex = nums[i] - 1;
                int temp = nums[i];
                nums[i] = nums[correctIndex];
                nums[correctIndex] = temp;
            }
        }

        // 第二步：遍历数组，找到第一个不匹配的位置
        for (int i = 0; i < n; i++) {
            if (nums[i] != i + 1) {
                return i + 1;
            }
        }

        // 如果所有位置都匹配，则缺失的是 n+1
        return n + 1;
    }
}
```

[缺失的第一个正数](https://leetcode.cn/problems/first-missing-positive)

#### 矩阵置零

```java
class Solution {
    public void setZeroes(int[][] matrix) {
        // 获取矩阵的行数 m 和列数 n
        int m = matrix.length, n = matrix[0].length;
        
        // 用于标记第一列是否需要置零
        boolean flagCol0 = false;

        // 第一次遍历：使用第一行和第一列作为标记数组
        for (int i = 0; i < m; i++) {
            // 如果第一列中的某一行是 0，则记录下来（最后统一处理整列）
            if (matrix[i][0] == 0) {
                flagCol0 = true;
            }

            // 遍历当前行的其余列（从第1列开始）
            for (int j = 1; j < n; j++) {
                // 如果当前位置 matrix[i][j] 是 0
                if (matrix[i][j] == 0) {
                    // 将该行的第一个元素（matrix[i][0]）和该列的第一个元素（matrix[0][j]）设为 0
                    // 这样就用第一行和第一列来标记哪些行和列需要置零
                    matrix[i][0] = matrix[0][j] = 0;
                }
            }
        }

        // 第二次遍历：根据第一行和第一列的标记，将对应位置置零
        for (int i = m - 1; i >= 0; i--) {
            // 从右下角向上遍历每一行
            for (int j = 1; j < n; j++) {
                // 如果当前行的第一个元素或当前列的第一个元素为 0
                // 说明这一行或这一列应该全部置零
                if (matrix[i][0] == 0 || matrix[0][j] == 0) {
                    matrix[i][j] = 0;
                }
            }

            // 处理第一列，如果 flagCol0 为 true，则当前行的第一个元素也置零
            if (flagCol0) {
                matrix[i][0] = 0;
            }
        }
    }
}
```

[矩阵置零](https://leetcode.cn/problems/set-matrix-zeroes)
