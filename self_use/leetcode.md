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
