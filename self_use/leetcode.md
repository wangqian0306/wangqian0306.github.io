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
        int[] sCount = new int[26];
        int[] pCount = new int[26];
        for (int i = 0; i < pLen; ++i) {
            ++sCount[s.charAt(i) - 'a'];
            ++pCount[p.charAt(i) - 'a'];
        }

        if (Arrays.equals(sCount, pCount)) {
            ans.add(0);
        }

        for (int i = 0; i < sLen - pLen; ++i) {
            --sCount[s.charAt(i) - 'a'];
            ++sCount[s.charAt(i + pLen) - 'a'];

            if (Arrays.equals(sCount, pCount)) {
                ans.add(i + 1);
            }
        }

        return ans;
    }
}
```

[找到字符串中所有字母异位词](https://leetcode.cn/problems/find-all-anagrams-in-a-string)
