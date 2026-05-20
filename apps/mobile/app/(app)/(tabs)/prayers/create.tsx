import { View, Text, TextInput, TouchableOpacity, StyleSheet, ScrollView, Alert, Switch } from 'react-native';
import { useState, useEffect } from 'react';
import { router, useNavigation } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { useColorScheme } from '../../../../src/hooks/useColorScheme';
import { prayersService } from '../../../../src/services/prayers';

export default function CreatePrayerScreen() {
  const { isDark } = useColorScheme();
  const insets = useSafeAreaInsets();
  const navigation = useNavigation();
  const [title, setTitle] = useState('');
  const [content, setContent] = useState('');
  const [isAnonymous, setIsAnonymous] = useState(false);
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const parent = navigation.getParent();
    if (parent) {
      parent.setOptions({ tabBarStyle: { display: 'none' }, tabBarVisible: false });
    }
    return () => {
      if (parent) {
        parent.setOptions({ tabBarStyle: { display: 'flex' }, tabBarVisible: true });
      }
    };
  }, [navigation]);

  const handleSubmit = async () => {
    if (!title.trim() || !content.trim()) {
      Alert.alert('Erro', 'Preencha o título e o conteúdo');
      return;
    }
    setLoading(true);
    try {
      const payload = {
        title: title.trim(),
        content: content.trim(),
        categoryId: undefined,
        isAnonymous: isAnonymous || false,
        isUrgent: false,
        isPublic: true,
      };
      await prayersService.create(payload as any);
      Alert.alert('✅', 'Pedido enviado com sucesso!', [
        { text: 'OK', onPress: () => router.back() }
      ]);
    } catch (error: any) {
      Alert.alert('Erro', error?.message || 'Falha ao enviar');
    } finally {
      setLoading(false);
    }
  };

  const bgColor = isDark ? '#0A0A0F' : '#F8FAFC';
  const cardBg = isDark ? '#1A1A2E' : '#FFFFFF';
  const textPrimary = isDark ? '#F9FAFB' : '#111827';
  const textSecondary = isDark ? '#9CA3AF' : '#6B7280';
  const borderColor = isDark ? '#1F2937' : '#E5E7EB';

  return (
    <View style={[styles.container, { backgroundColor: bgColor, paddingTop: insets.top }]}>
      <View style={styles.header}>
        <TouchableOpacity onPress={() => router.back()} style={styles.backBtn}>
          <Text style={[styles.backText, { color: textPrimary }]}>←</Text>
        </TouchableOpacity>
        <Text style={[styles.title, { color: textPrimary }]}>Novo Pedido</Text>
        <View style={{ width: 40 }} />
      </View>

      <ScrollView contentContainerStyle={styles.content} keyboardShouldPersistTaps="handled">
        <View style={[styles.card, { backgroundColor: cardBg }]}>
          <Text style={[styles.label, { color: textSecondary }]}>Título</Text>
          <TextInput
            value={title}
            onChangeText={setTitle}
            placeholder="Do que você precisa orar?"
            placeholderTextColor={textSecondary}
            style={[styles.input, { color: textPrimary, borderColor }]}
          />
        </View>

        <View style={[styles.card, { backgroundColor: cardBg }]}>
          <Text style={[styles.label, { color: textSecondary }]}>Pedido</Text>
          <TextInput
            value={content}
            onChangeText={setContent}
            placeholder="Compartilhe os detalhes..."
            placeholderTextColor={textSecondary}
            multiline
            numberOfLines={4}
            textAlignVertical="top"
            style={[styles.input, styles.textArea, { color: textPrimary, borderColor }]}
          />
        </View>

        <View style={[styles.optionRow, { backgroundColor: cardBg }]}>
          <View>
            <Text style={[styles.optionTitle, { color: textPrimary }]}>Pedido anônimo</Text>
            <Text style={[styles.optionDesc, { color: textSecondary }]}>Seu nome não será exibido</Text>
          </View>
          <Switch
            value={isAnonymous}
            onValueChange={setIsAnonymous}
            trackColor={{ false: borderColor, true: '#008CFF80' }}
            thumbColor={isAnonymous ? '#008CFF' : textSecondary}
          />
        </View>

        <TouchableOpacity
          onPress={handleSubmit}
          disabled={loading || !title.trim() || !content.trim()}
          style={[
            styles.submitBtn,
            { backgroundColor: !title.trim() || !content.trim() ? '#6B7280' : '#008CFF' }
          ]}
        >
          <Text style={styles.submitText}>
            {loading ? 'Enviando...' : 'Enviar Pedido'}
          </Text>
        </TouchableOpacity>
      </ScrollView>
    </View>
  );
}

const styles = StyleSheet.create({
  container: { flex: 1 },
  header: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', paddingHorizontal: 20, paddingVertical: 16 },
  backBtn: { width: 40, height: 40, alignItems: 'center', justifyContent: 'center' },
  backText: { fontSize: 28 },
  title: { fontSize: 18, fontWeight: '600' },
  content: { padding: 20, paddingBottom: 40 },
  card: { borderRadius: 16, padding: 16, marginBottom: 16 },
  label: { fontSize: 14, marginBottom: 10 },
  input: { fontSize: 16, borderWidth: 1, borderRadius: 12, padding: 14 },
  textArea: { minHeight: 100, textAlignVertical: 'top' },
  categories: { flexDirection: 'row', flexWrap: 'wrap', gap: 8 },
  optionRow: { flexDirection: 'row', alignItems: 'center', justifyContent: 'space-between', padding: 16, borderRadius: 16, marginBottom: 20 },
  optionTitle: { fontSize: 15, fontWeight: '500' },
  optionDesc: { fontSize: 12, marginTop: 2 },
  submitBtn: { borderRadius: 12, padding: 16, alignItems: 'center' },
  submitText: { fontSize: 16, fontWeight: '600', color: '#FFFFFF' },
});