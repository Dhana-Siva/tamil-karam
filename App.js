import React, { useState, useEffect, useRef } from 'react';
import {
  StyleSheet,
  Text,
  View,
  TextInput,
  TouchableOpacity,
  ScrollView,
  ActivityIndicator,
  SafeAreaView,
  StatusBar,
  Alert,
  Keyboard,
  Animated,
} from 'react-native';
import * as Clipboard from 'expo-clipboard';
import * as Haptics from 'expo-haptics';
import * as Application from 'expo-application';
import AsyncStorage from '@react-native-async-storage/async-storage';

const WORKER_URL = 'https://tamil-grammar-fix.dhanageetha2000.workers.dev/';
const FREE_LIMIT = 30;

// ── Get or create a stable device ID ─────────────────────────────────────────
async function getDeviceId() {
  const vendorId = await Application.getIosIdForVendorAsync?.();
  if (vendorId) return vendorId;
  const stored = await AsyncStorage.getItem('device_id');
  if (stored) return stored;
  const id = `${Date.now()}-${Math.random().toString(36).slice(2)}`;
  await AsyncStorage.setItem('device_id', id);
  return id;
}

// ── Main component ────────────────────────────────────────────────────────────
export default function App() {
  const [inputText, setInputText]         = useState('');
  const [correctedText, setCorrectedText] = useState('');
  const [isLoading, setIsLoading]         = useState(false);
  const [error, setError]                 = useState('');
  const [usage, setUsage]                 = useState(null);
  const [copied, setCopied]               = useState(false);
  const fadeAnim = useRef(new Animated.Value(0)).current;

  useEffect(() => {
    if (correctedText) {
      Animated.spring(fadeAnim, { toValue: 1, useNativeDriver: true, friction: 8 }).start();
    } else {
      fadeAnim.setValue(0);
    }
  }, [correctedText]);

  const fixGrammar = async () => {
    const text = inputText.trim();
    if (!text) {
      Alert.alert('உரை இல்லை', 'தயவுசெய்து தமிழ் உரையை உள்ளிடுங்கள்.');
      return;
    }
    Keyboard.dismiss();
    setIsLoading(true);
    setError('');
    setCorrectedText('');
    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Medium);

    try {
      const deviceId = await getDeviceId();
      const response = await fetch(WORKER_URL, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ text, deviceId }),
      });
      const data = await response.json();

      if (!response.ok) {
        if (response.status === 429) {
          setError(`இந்த மாதம் ${FREE_LIMIT} இலவச திருத்தங்கள் முடிந்தன.\nஅடுத்த மாதம் மீண்டும் பயன்படுத்தலாம்.`);
        } else {
          setError(data.error || 'சர்வர் பிழை ஏற்பட்டது. மீண்டும் முயற்சிக்கவும்.');
        }
        await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
        return;
      }

      setCorrectedText(data.corrected || '');
      if (data.usage != null) setUsage({ used: data.usage, limit: data.limit });
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Success);
    } catch {
      setError('இணைய இணைப்பு இல்லை. மீண்டும் முயற்சிக்கவும்.');
      await Haptics.notificationAsync(Haptics.NotificationFeedbackType.Error);
    } finally {
      setIsLoading(false);
    }
  };

  const copyToClipboard = async () => {
    await Clipboard.setStringAsync(correctedText);
    await Haptics.impactAsync(Haptics.ImpactFeedbackStyle.Light);
    setCopied(true);
    setTimeout(() => setCopied(false), 2000);
  };

  const clearAll = () => {
    setInputText('');
    setCorrectedText('');
    setError('');
  };

  return (
    <SafeAreaView style={styles.container}>
      <StatusBar barStyle="light-content" backgroundColor={NAVY} />

      {/* ── Header ── */}
      <View style={styles.header}>
        <View>
          <Text style={styles.headerTitle}>தமிழ் கரம் ✓</Text>
          <Text style={styles.headerSubtitle}>Tamil Grammar Fix</Text>
        </View>
        {usage && (
          <View style={styles.usagePill}>
            <Text style={styles.usagePillText}>{usage.limit - usage.used} மீதம்</Text>
          </View>
        )}
      </View>

      <ScrollView
        style={styles.scroll}
        contentContainerStyle={styles.scrollContent}
        keyboardShouldPersistTaps="handled"
      >
        {/* ── Input card ── */}
        <View style={styles.card}>
          <Text style={styles.cardLabel}>உங்கள் உரை</Text>
          <TextInput
            style={styles.textInput}
            multiline
            placeholder="இங்கே தமிழ் உரையை உள்ளிடுங்கள்…"
            placeholderTextColor="#bbb"
            value={inputText}
            onChangeText={setInputText}
            textAlignVertical="top"
            autoCorrect={false}
            spellCheck={false}
          />
          <View style={styles.inputFooter}>
            <Text style={styles.charCount}>{inputText.length} எழுத்துக்கள்</Text>
            {inputText.length > 0 && (
              <TouchableOpacity onPress={clearAll}>
                <Text style={styles.clearLink}>அழி</Text>
              </TouchableOpacity>
            )}
          </View>
        </View>

        {/* ── Fix button ── */}
        <TouchableOpacity
          style={[styles.fixButton, (isLoading || !inputText.trim()) && styles.fixButtonDisabled]}
          onPress={fixGrammar}
          disabled={isLoading || !inputText.trim()}
          activeOpacity={0.8}
        >
          {isLoading
            ? <ActivityIndicator color="#fff" size="small" />
            : <Text style={styles.fixButtonText}>✓  இலக்கணம் சரிசெய்</Text>
          }
        </TouchableOpacity>

        {/* ── Error ── */}
        {!!error && (
          <View style={styles.errorCard}>
            <Text style={styles.errorText}>{error}</Text>
          </View>
        )}

        {/* ── Result card ── */}
        {!!correctedText && (
          <Animated.View style={[styles.card, styles.resultCard, {
            opacity: fadeAnim,
            transform: [{ translateY: fadeAnim.interpolate({ inputRange: [0, 1], outputRange: [20, 0] }) }],
          }]}>
            <Text style={styles.cardLabel}>சரிசெய்யப்பட்ட உரை ✅</Text>
            <Text style={styles.correctedText} selectable>{correctedText}</Text>
            <TouchableOpacity
              style={[styles.copyButton, copied && styles.copyButtonDone]}
              onPress={copyToClipboard}
              activeOpacity={0.8}
            >
              <Text style={styles.copyButtonText}>
                {copied ? '✓  நகலெடுக்கப்பட்டது!' : '📋  நகலெடு'}
              </Text>
            </TouchableOpacity>
          </Animated.View>
        )}

        {/* ── Usage bar ── */}
        {usage && (
          <View style={styles.usageBarWrap}>
            <View style={[styles.usageFill, { width: `${(usage.used / usage.limit) * 100}%` }]} />
            <Text style={styles.usageBarLabel}>
              {usage.used} / {usage.limit} இலவச திருத்தங்கள் இந்த மாதம்
            </Text>
          </View>
        )}

        <View style={{ height: 40 }} />
      </ScrollView>
    </SafeAreaView>
  );
}

// ── Colours ───────────────────────────────────────────────────────────────────
const NAVY  = '#1a1a2e';
const RED   = '#e63946';
const GREEN = '#2d6a4f';
const LGREY = '#f5f5f7';

// ── Styles ────────────────────────────────────────────────────────────────────
const styles = StyleSheet.create({
  container: { flex: 1, backgroundColor: LGREY },

  header: {
    backgroundColor: NAVY,
    paddingVertical: 16,
    paddingHorizontal: 20,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  headerTitle:    { fontSize: 24, fontWeight: '700', color: '#fff', letterSpacing: 0.5 },
  headerSubtitle: { fontSize: 12, color: '#aaa', marginTop: 2, letterSpacing: 1 },
  usagePill:      { backgroundColor: 'rgba(255,255,255,0.15)', borderRadius: 20, paddingVertical: 4, paddingHorizontal: 12 },
  usagePillText:  { color: '#fff', fontSize: 13, fontWeight: '600' },

  scroll:        { flex: 1 },
  scrollContent: { padding: 16 },

  card: {
    backgroundColor: '#fff',
    borderRadius: 16,
    padding: 16,
    marginBottom: 14,
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.07,
    shadowRadius: 8,
    elevation: 3,
  },
  resultCard: { borderLeftWidth: 4, borderLeftColor: GREEN },
  cardLabel:  { fontSize: 11, fontWeight: '700', color: '#999', letterSpacing: 1, textTransform: 'uppercase', marginBottom: 10 },

  textInput:   { fontSize: 18, color: '#111', minHeight: 130, lineHeight: 28 },
  inputFooter: { flexDirection: 'row', justifyContent: 'space-between', marginTop: 8 },
  charCount:   { fontSize: 12, color: '#bbb' },
  clearLink:   { fontSize: 12, color: RED, fontWeight: '600' },

  fixButton: {
    backgroundColor: RED,
    borderRadius: 14,
    paddingVertical: 16,
    alignItems: 'center',
    marginBottom: 14,
    shadowColor: RED,
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.35,
    shadowRadius: 8,
    elevation: 5,
  },
  fixButtonDisabled: { backgroundColor: '#ddd', shadowOpacity: 0, elevation: 0 },
  fixButtonText:     { color: '#fff', fontSize: 18, fontWeight: '700', letterSpacing: 0.5 },

  errorCard: {
    backgroundColor: '#fff0f0',
    borderRadius: 12,
    padding: 14,
    marginBottom: 14,
    borderLeftWidth: 4,
    borderLeftColor: RED,
  },
  errorText: { color: '#c0392b', fontSize: 14, lineHeight: 22 },

  correctedText: { fontSize: 18, color: '#111', lineHeight: 28, marginBottom: 14 },
  copyButton:    { backgroundColor: GREEN, borderRadius: 10, paddingVertical: 10, paddingHorizontal: 18, alignSelf: 'flex-end' },
  copyButtonDone: { backgroundColor: '#555' },
  copyButtonText: { color: '#fff', fontWeight: '700', fontSize: 14 },

  usageBarWrap: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 14,
    marginBottom: 14,
    overflow: 'hidden',
    position: 'relative',
  },
  usageFill:     { position: 'absolute', left: 0, top: 0, bottom: 0, backgroundColor: '#e8f5e9', borderRadius: 12 },
  usageBarLabel: { fontSize: 12, color: '#888', textAlign: 'center' },
});
